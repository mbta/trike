#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use Time::HiRes qw(sleep);

# Auto-flush socket IO
$| = 1;

my $port = 7777;
my $server = 'localhost';

while(1) {
    print "CLIENT: Attempting to connect to $server:$port...\n";
    my $socket = new IO::Socket::INET (
        PeerHost => $server,
        PeerPort => $port,
        Proto => 'tcp',
    );

    if ($socket) {
        print "CLIENT: Connected to the server.\n";
        my $number = 1;
        while(1) {
            my $data = "$number\n";
            my $size;
            if ($socket->connected()) {
                $size = $socket->send($data);
                print "CLIENT: Sent data: $data $size bytes\n";
            } else {
                print "CLIENT: Connection lost or send error: $!\n";
                last; # Exit the loop if send failed
            }

            $number++;
            sleep(0.25); # Send a number every quarter second
        }
    } else {
        print "CLIENT: Connection failed. Retrying in 2 seconds...\n";
        sleep(2);
    }

    # Close the socket before retrying
    if ($socket) {
        close($socket);
    }
}
