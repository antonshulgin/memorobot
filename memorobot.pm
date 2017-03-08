package memorobot;

use strict;
use warnings;

use constant DICT_FILENAME => 'dict.tsv';

sub parse_input {
	shift;
	my $input = sanitize_string(shift);
	if (!length($input)) {
		return "no stuff to parse";
	}
	if (is_command($input)) {
		return parse_command($input);
	}
	return find_memo($input);
}

sub parse_command {
	my @input = split(" ", shift);
	my $command = join(" ", @input);
	my $command_pattern_add = '^@add\s+([0-9a-z\-_]+)\s+(.+)$';
	if ($command =~ m/${command_pattern_add}/) {
		return add_memo($1, $2);
	}
	return "something isn't right with this command.";
}

sub add_memo {
	my $term = sanitize_string(shift);
	my $description = sanitize_string(shift);
	if (!length($term) || !length($description)) {
		return 'usage: @add <term> <description>';
	}
	if (find_memo($term)) {
		return 'already exists';
	}
	return write_file(DICT_FILENAME, "$term\t$description\n");
}

sub write_file {
	my $filename = sanitize_string(shift);
	my $description = sanitize_string(shift);
	if (!length($filename)) {
		die("No filename provided.\n");
	}
	if (!length($description)) {
		die("No description provided.\n");
	}
	open(FILE, '>>', $filename);
	print FILE "$description\n";
	close(FILE);
	return "Done.";
}

sub find_memo {
	my $term = sanitize_string(shift);
	my @memos = read_file(DICT_FILENAME);
	for my $memo (@memos) {
		if ($memo =~ m/^${term}\t+(.+)$/gmi) {
			return $1;
		}
	}
}

sub read_file {
	my $filename = sanitize_string(shift);
	if (!length($filename)) {
		die("No filename provided.\n");
	}
	my @file_content;
	open(FILE, '<', $filename);
	@file_content = <FILE>;
	close(FILE);
	return @file_content;
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
