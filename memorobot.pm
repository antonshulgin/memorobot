package memorobot;

use strict;
use warnings;

my $DICT_PATH = 'dict.tsv';
my $OBEY_PATH = 'obey.tsv';

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
		return 'No stuff to parse';
	}
	if (is_command($input)) {
		if (!find_supervisor($sender)) {
			return 'You are not my supervisor';
		}
		return parse_command($input);
	}
	return lookup($input);
}

sub parse_command {
	my $command_string = sanitize_string(shift);
	if (!length($command_string)) {
		return 'No';
	}
	my ($command, $params) = ($command_string =~ m/^@([^\s]+)\s+(.+)$/);
	# TODO: do the switch or a hash map
	if ($command eq 'add') {
		return add_memo($params);
	}
	if ($command eq 'remove') {
		return remove_memo($params);
	}
	if ($command eq 'obey') {
		return add_supervisor($params);
	}
	if ($command eq 'disobey') {
		return remove_supervisor($params);
	}
	return 'No comprendo, amigo';
}

sub lookup {
	my $term = sanitize_string(shift);
	if (!length($term)) {
		return 'Usage: <my nickname> <term>';
	}
	my $memo = find_memo($term);
	if (!$memo) {
		return "No such thing as '$term'";
	}
	return $memo;
}

sub remove_memo {
	my $term = sanitize_string(shift);
	if (!find_memo($term)) {
		return "No such thing as '$term'";
	}
	my @memos = get_memos();
	my @new_memos;
	for my $memo (@memos) {
		if ($memo !~ m/^${term}\t/i) {
			push(@new_memos, $memo);
		}
	}
	open(DICT_FILE, '>', get_dict_path());
	print DICT_FILE @new_memos;
	close(DICT_FILE);
	return "Removed '$term'";
}

sub add_memo {
	my $params = sanitize_string(shift);
	my ($term, $text) = ($params =~ m/^([^\s]+)\s+(.+)$/i);
	if (find_memo($term)) {
		return "'$term' already exists";
	}
	open(DICT_FILE, '>>', get_dict_path());
	print DICT_FILE "$term\t$text\n";
	close(DICT_FILE);
	return "Added '$term'";
}

sub find_memo {
	my $term = sanitize_string(shift);
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

sub get_memos {
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
	my @supervisors = get_supervisors();
	my @new_supervisors;
	for my $supervisor (@supervisors) {
		if ($nickname ne sanitize_string($supervisor)) {
			push(@new_supervisors, $supervisor);
		}
	}
	open(OBEY_FILE, '>', get_obey_path());
	print OBEY_FILE @new_supervisors;
	close(OBEY_FILE);
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
	open(OBEY_FILE, '>>', get_obey_path());
	print OBEY_FILE "$nickname\n";
	close(OBEY_FILE);
	return "$nickname is now my supervisor";
}

sub find_supervisor {
	my $nickname = sanitize_string(shift);
	if (!length($nickname)) {
		return;
	}
	my @supervisors = get_supervisors();
	for my $supervisor (@supervisors) {
		if ($nickname eq sanitize_string($supervisor)) {
			return $supervisor;
		}
	}
	return;
}

sub get_supervisors {
	my @supervisors;
	open(OBEY_FILE, '<', get_obey_path());
	@supervisors = <OBEY_FILE>;
	close(OBEY_FILE);
	return @supervisors;
}

sub is_command {
	my $query = shift;
	return ($query =~ m/^@\w+/);
}

sub sanitize_string {
	my $string = shift;
	$string =~ s/^\s+|\n|\r|\s+$//;
	$string =~ s/\s{2,}//gi;
	return $string;
}

1;
