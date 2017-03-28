package memorobot;

use strict;
use warnings;

use URI::Escape;

my $DICT_PATH = 'dict.tsv';
my $OBEY_PATH = 'obey.tsv';

my $COMMAND_PREFIX = '@';
my $USER_COMMAND_PREFIX = '!';

my @CACHED_MEMOS;
my @CACHED_SUPERVISORS;

sub get_obey_path {
	return $OBEY_PATH;
}

sub set_obey_path {
	shift;
	my $obey_path = sanitize_string(shift);
	print("set_obey_path '$obey_path'\n");
	if (!length($obey_path)) {
		return;
	}
	$OBEY_PATH = $obey_path;
}

sub get_dict_path {
	return $DICT_PATH;
}

sub set_dict_path {
	shift;
	my $dict_path = sanitize_string(shift);
	print("set_dict_path '$dict_path'\n");
	if (!length($dict_path)) {
		return;
	}
	$DICT_PATH = $dict_path;
}

sub parse_input {
	shift;
	my $input = sanitize_string(shift);
	my $sender = sanitize_string(shift);
	if (!length($input)) {
		return 'Give me a word';
	}
	if (is_command($input)) {
		if (!find_supervisor($sender)) {
			return 'You are not my supervisor';
		}
		return parse_command($input);
	}
	if (is_user_command($input)) {
		return parse_user_command($input);
	}
	return lookup($input);
}

sub parse_user_command {
	my $command_string = sanitize_string(shift);
	if (!length($command_string)) {
		return 'Nope';
	}
	my ($command, $params) = ($command_string =~ m/^${USER_COMMAND_PREFIX}([^\s]+)\s?(.*)$/);
	if ($command eq 'list') { return list_terms($params); }
	if ($command eq 'help') { return send_help(); }
	return 'Nie rozumiem';
}

sub send_help {
	return 'Everything you ever wanted to know but were too afraid to ask: https://github.com/antonshulgin/memorobot';
}

sub list_terms {
	my $pattern = uri_escape(sanitize_string(shift));
	my $is_pattern_empty = !length($pattern);
	my @memos = get_memos();
	if (!scalar(@memos)) {
		return 'Got nothing, try @adding some memos first';
	}
	if ((scalar(@memos) > 30) && $is_pattern_empty) {
		return 'Too many memos, try `!list <first letter(s)>`';
	}
	my $memos_string = join('', @memos);
	my @matching_terms;
	if ($is_pattern_empty) {
		@matching_terms = ($memos_string =~ m/^([^\t]+)/gmi);
	} else {
		@matching_terms = ($memos_string =~ m/^([^\t]*${pattern}[^\t]*)/gmi);
	}
	if (!scalar(@matching_terms)) {
		return 'Nothing found';
	}
	my $matching_terms_string = join(' :: ', @matching_terms);
	return uri_unescape(sanitize_string($matching_terms_string));
}

sub parse_command {
	my $command_string = sanitize_string(shift);
	if (!length($command_string)) {
		return 'No';
	}
	my ($command, $params) = ($command_string =~ m/^${COMMAND_PREFIX}([^\s]+)\s+(.+)$/);
	# TODO: do the switch or a hash map
	if ($command eq 'add') { return add_memo($params); }
	if ($command eq 'update') { return update_memo($params); }
	if ($command eq 'remove') { return remove_memo($params); }
	if ($command eq 'obey') { return add_supervisor($params); }
	if ($command eq 'disobey') { return remove_supervisor($params); }
	return 'No comprendo, amigo';
}

sub lookup {
	my $input = sanitize_string(shift);
	my ($term, $nickname) = ($input =~ m/^([^\s]+)\s?(.*)$/i);
	if (!length($term)) {
		return 'Usage: <my nickname> <term>';
	}
	my $memo = find_memo($term);
	if (!$memo) {
		return "No such thing as `$term`";
	}
	return !length($nickname) ? $memo : "$nickname: $memo";
}

sub remove_memo {
	my $term = sanitize_string(shift);
	if (!length($term)) {
		return 'Usage: @remove <term>'
	}
	if (!find_memo($term)) {
		return "No such thing as `$term`";
	}
	my $escaped_term = uri_escape($term);
	my @memos = get_memos();
	my @new_memos;
	for my $memo (@memos) {
		if ($memo !~ m/^${escaped_term}\t/i) {
			push(@new_memos, $memo);
		}
	}
	write_memos(@new_memos);
	cache_memos(read_memos());
	return "Removed `$term`";
}

sub update_memo {
	my $params = sanitize_string(shift);
	my ($term, $text) = ($params =~ m/^([^\s]+)\s+(.+)$/i);
	$term = sanitize_string($term);
	$text = sanitize_string($text);
	if (!length($text)) {
		return 'Usage: @update <term> <text>';
	}
	if (!find_memo($term)) {
		return "`$term` doesn't exist";
	}
	my $escaped_term = uri_escape($term);
	my @memos = get_memos();
	my @new_memos;
	for my $memo (@memos) {
		if ($memo !~ m/^${escaped_term}\t/i) {
			push(@new_memos, $memo);
		}
	}
	open(DICT_FILE, '>', get_dict_path());
	print DICT_FILE @new_memos;
	print DICT_FILE "$escaped_term\t$text\n";
	close(DICT_FILE);
	cache_memos(read_memos());
	return "Updated `$term`";
}

sub add_memo {
	my $params = sanitize_string(shift);
	my ($term, $text) = ($params =~ m/^([^\s]+)\s+(.+)$/i);
	$term = sanitize_string($term);
	$text = sanitize_string($text);
	if (!length($text)) {
		return 'Usage: @add <term> <text>';
	}
	if (find_memo($term)) {
		return "`$term` already exists";
	}
	my $escaped_term = uri_escape($term);
	open(DICT_FILE, '>>', get_dict_path());
	print DICT_FILE "$escaped_term\t$text\n";
	close(DICT_FILE);
	cache_memos(read_memos());
	return "Added `$term`";
}

sub find_memo {
	my $term = uri_escape(sanitize_string(shift));
	if (!length($term)) {
		return 'Usage: <my nickname> <word>';
	}
	my @memos = get_memos();
	for my $memo (@memos) {
		if ($memo =~ m/^${term}\t(.+)$/i) {
			return $1;
		}
	}
	return;
}

sub cache_memos {
	my @memos = @_;
	@CACHED_MEMOS = sort(@memos);
}

sub get_memos {
	return @CACHED_MEMOS;
}

sub init {
	cache_memos(read_memos());
	cache_supervisors(read_supervisors());
}

sub write_memos {
	my @memos = @_;
	open(DICT_FILE, '>', get_dict_path());
	@memos = <DICT_FILE>;
	close(DICT_FILE);
}

sub read_memos {
	print('Reading memos from ' . get_dict_path() . "\n");
	my @memos;
	open(DICT_FILE, '<', get_dict_path());
	@memos = <DICT_FILE>;
	close(DICT_FILE);
	return @memos;
}

sub remove_supervisor {
	my $nickname = sanitize_string(shift);
	if (!find_supervisor($nickname)) {
		return "$nickname is not my supervisor";
	}
	my $escaped_nickname = uri_escape($nickname);
	my @supervisors = get_supervisors();
	my @new_supervisors;
	for my $supervisor (@supervisors) {
		if (sanitize_string($supervisor) ne $escaped_nickname) {
			push(@new_supervisors, $supervisor);
		}
	}
	open(OBEY_FILE, '>', get_obey_path());
	print OBEY_FILE @new_supervisors;
	close(OBEY_FILE);
	cache_supervisors(read_supervisors());
	return "$nickname is no longer my supervisor";
}

sub add_supervisor {
	my $nickname = sanitize_string(shift);
	if (!length($nickname)) {
		return 'Can\'t obey nobody';
	}
	if (find_supervisor($nickname)) {
		return "$nickname is already my supervisor";
	}
	my $escaped_nickname = uri_escape($nickname);
	open(OBEY_FILE, '>>', get_obey_path());
	print OBEY_FILE "$escaped_nickname\n";
	close(OBEY_FILE);
	cache_supervisors(read_supervisors());
	return "$nickname is now my supervisor";
}

sub find_supervisor {
	my $nickname = uri_escape(sanitize_string(shift));
	if (!length($nickname)) {
		return;
	}
	my @supervisors = get_supervisors();
	for my $supervisor (@supervisors) {
		if (sanitize_string($supervisor) eq $nickname) {
			return $supervisor;
		}
	}
	return;
}

sub cache_supervisors {
	my @supervisors = @_;
	@CACHED_SUPERVISORS = sort(@supervisors);
}

sub read_supervisors {
	my @supervisors;
	open(OBEY_FILE, '<', get_obey_path());
	@supervisors = <OBEY_FILE>;
	close(OBEY_FILE);
	return @supervisors;
}

sub get_supervisors {
	return @CACHED_SUPERVISORS;
}

sub is_user_command {
	my $query = shift;
	return ($query =~ m/^${USER_COMMAND_PREFIX}\w+/);
}

sub is_command {
	my $query = shift;
	return ($query =~ m/^${COMMAND_PREFIX}\w+/);
}

sub sanitize_string {
	my $string = shift;
	if (!length($string)) {
		return;
	}
	$string =~ s/^\s+|\n|\r|\s+$//;
	$string =~ s/\s{2,}//gi;
	return $string;
}

1;
