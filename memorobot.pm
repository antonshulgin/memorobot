package memorobot;

use strict;
use warnings;

use constant DICT_PATH => 'dict.tsv';

sub parse_input {
	shift;
	my $input = sanitize_string(shift);
	if (!length($input)) {
		return "no stuff to parse";
	}
	if (is_command($input)) {
		return parse_command($input);
	}
	return lookup($input);
}

sub parse_command {
	my $command_string = sanitize_string(shift);
	my ($command, $params) = ($command_string =~ m/^@([^\s]+)\s+(.+)$/);
	print("performing '$command' with params '$params'...\n");
	if ($command =~ m/^add$/i) {
		return add_memo($params);
	}
	if ($command =~ m/^remove$/i) {
		return remove_memo($params);
	}
	return "No"
}

sub lookup {
	my $term = sanitize_string(shift);
	my $memo = find_memo($term);
	if (!$memo) {
		return "No such thing as '$term'";
	}
	return $memo;
}

sub remove_memo {
	my $term = sanitize_string(shift);
	if (!length($term)) {
		return "no stuff to look up";
	}
	if (!find_memo($term)) {
		return "No such thing as '$term'";
	}
	print("looking up '$term'...\n");
	my @memos = get_memos();
	my @new_memos;
	for my $memo (@memos) {
		if ($memo !~ m/^${term}\t/i) {
			push(@new_memos, $memo);
		}
	}
	open(DICT_FILE, '>', DICT_PATH);
	print DICT_FILE @new_memos;
	close(DICT_FILE);
	return "Removed '$term'";
}

sub add_memo {
	my $params = sanitize_string(shift);
	my ($term, $text) = ($params =~ m/^([^\s]+)\s+(.+)$/i);
	print("adding '$term' as '$text'...\n");
	if (find_memo($term)) {
		return "'$term' already exists";
	}
	open(DICT_FILE, '>>', DICT_PATH);
	print DICT_FILE "$term\t$text\n";
	close(DICT_FILE);
	return "Added '$term'";
}

sub find_memo {
	my $term = sanitize_string(shift);
	if (!length($term)) {
		return "no stuff to look up";
	}
	print("looking up '$term'...\n");
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
	open(DICT_FILE, '<', DICT_PATH);
	@memos = <DICT_FILE>;
	close(DICT_FILE);
	return @memos;
}

sub is_command {
	my $query = shift;
	return ($query =~ m/^@\w+/);
}

sub sanitize_string {
	my $string = shift;
	$string =~ s/^\s+|\s+$//;
	$string =~ s/\s{2,}//gi;
	return $string;
}

1;
