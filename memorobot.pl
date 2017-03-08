#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use memorobot;

init(@ARGV);

sub init {
	if (scalar(@_) < 4) {
		die("Usage: $0 <server> <port> <nickname> \"<#channel1,#channel2,#etc>\"\n");
	}
	my $server = shift;
	my $port = shift;
	my $nickname = shift;
	my @channels = parse_channels(shift);
	my $socket = IO::Socket::INET->new(
		PeerAddr => $server,
		PeerPort => $port,
		Proto => 'tcp'
	);
	print("Connecting to $server:$port as $nickname\n");
	if ($socket) {
		print("Connected\n");
		authenticate($socket, $nickname, $server);
		join_channels($socket, @channels);
		dispatch($socket, $nickname);
	}
}

sub dispatch {
	my $socket = shift;
	my $nickname = shift;
	my $sender;
	my $message;
	my $response;
	while (my $message = <$socket>) {
		if ($message =~ /^PING\s+\:([\w.]+)/) {
			print $socket "PONG $1\n";
			print "Ping? Pong.\n";
		}
		if ($message =~ /^\S+\s+PRIVMSG\s+(\S+)\s+\:${nickname}\W?\s*(.+)$/) {
			$sender = $1;
			$message = $2;
			$message =~ s/^\s*|\s*$//;
			$response = memorobot->parse_input($message);
			if (defined($response)) {
				print $socket "PRIVMSG $sender :$response\n";
			}
		}
	}
}

sub parse_channels {
	my $channels = shift;
	$channels =~ s/\s//g;
	return split(',', $channels);
}

sub join_channels {
	my $socket = shift;
	my @channels = @_;
	for my $channel (@channels) {
		print "Joining $channel\n";
		print $socket "JOIN :$channel\n";
	}
}

sub authenticate {
	my $socket = shift;
	my $nickname = shift;
	my $server = shift;
	print $socket "USER $nickname internets $server :derp\n";
	print $socket "NICK $nickname\n";
}
