#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use memorobot;

#lookup(@ARGV);

#sub lookup {
	#my $input = join(" ", @_);
	#my $result = memorobot->parse_input($input);
	#print(">>> $result\n");
#}

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
	my $channel;
	my $message;
	my $response;
	my $pattern_ping = qr/^PING\s+\:([\w.]+)/;
	my $pattern_privmsg = qr/^\:([^\!]+).+PRIVMSG\s+(\S+)\s+\:${nickname}\W?\s*(.+)$/;
	while (my $message = <$socket>) {
		if ($message =~ $pattern_ping) {
			print $socket "PONG $1\n";
			print "Ping? Pong.\n";
		}
		if ($message =~ $pattern_privmsg) {
			$sender = $1;
			$channel = $2;
			$message = $3;
			$message =~ s/^\s*|\s*$//;
			print "'$sender' -> '$channel': '$message'\n";
			$response = memorobot->parse_input($message, $sender);
			if (defined($response)) {
				print $socket "PRIVMSG $channel :$response\n";
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
