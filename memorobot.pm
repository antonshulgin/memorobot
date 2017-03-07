package memorobot;

use strict;
use warnings;

use constant DICT_FILENAME => 'dict.tsv';

sub parse {
	shift;
	my $query = sanitize(@_);
	if (!length($query)) {
		return "no stuff to parse";
	}
	if (is_command($query)) {
		return parse_command($query);
	}
	return find_memo($query);
}

sub parse_command {
	my @input = split(" ", shift);
	my $command = join(" ", @input);
	my $command_pattern_add = '^@add\s+([^\:]+)\:(.+)$';
	if ($command =~ m/${command_pattern_add}/) {
		return add_memo($1, $2);
	}
	return "something isn't right with this command.";
}

sub add_memo {
	my $title = sanitize(shift);
	my $text = sanitize(shift);
	if (!length($title) || !length($text)) {
		return 'usage: @add <title>: <text>';
	}
	if (find_memo($title)) {
		return 'already exists';
	}
	return write_file(DICT_FILENAME, "$title\t$text\n");
}

sub write_file {
	my $filename = sanitize(shift);
	my $text = sanitize(shift);
	if (!length($filename)) {
		die("No filename provided.\n");
	}
	if (!length($text)) {
		die("No text provided.\n");
	}
	open(FILE, '>>', $filename);
	print FILE "$text\n";
	close(FILE);
	return "Done.";
}

sub find_memo {
	my $term = sanitize(shift);
	my @memos = read_file(DICT_FILENAME);
	for my $memo (@memos) {
		if ($memo =~ m/^${term}\t+(.+)$/gmi) {
			return $1;
		}
	}
	return undef;
}

sub read_file {
	my $filename = sanitize(shift);
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

sub sanitize {
	my $query = shift;
	$query =~ s/^\s+|\s+$//;
	$query =~ s/\s{2,}//gi;
	return $query;
}

1;
