#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;

# Auto-flush socket IO
$| = 1;

# Creating a listening socket
my $socket = new IO::Socket::INET(
    LocalAddr => 'localhost',
    LocalPort => '7777',
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "ERROR in Socket Creation : $!\n";

print "SERVER: Listening on port 7777...\n";

while (1) {

    # Accepting a connection
    my $client_socket  = $socket->accept();
    my $client_address = $client_socket->peerhost();
    my $client_port    = $client_socket->peerport();
    print "SERVER: Accepted connection from $client_address:$client_port\n";

    # Using a child process to handle the connection
    my $child_pid = fork();
    if ( $child_pid == 0 ) {

        # Child process
        while (1) {

            # Reading client's message
            my $data = "";
            $client_socket->recv( $data, 1024 );
            last if not $data;

            print "SERVER: Received data: $data";

            # Simulate random disconnect
            if ( int( rand(10) ) < 2 )
            {    # Approximately 20% chance to disconnect
                print
"SERVER: Terminating connection with $client_address:$client_port\n";
                last;
            }
        }
        $client_socket->close();
        print "SERVER: Connection closed. Listening for new connections...\n";
        exit(0);    # Exit the child process
    }

    # Parent process continues to listen for new connections
}

$socket->close();
