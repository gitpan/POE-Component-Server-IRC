package POE::Component::Server::IRC;

use strict;
use warnings;
use POE qw/
  Filter::Line
  Filter::Stackable
  Filter::IRCD;
  Wheel::ReadWrite
  Wheel::SocketFactory
  Driver::SysRW
  Component::Server::IRC::auth;
  Component::Server::IRC::client;
/;

use Socket;
use vars qw/$VERSION/;

$VERSION = '0.0001';

my $server_host = 'ryoko';

sub new {
    my $class = shift;
    my $server = shift;

    POE::Session->create(
        inline_states	=> {
            _start	=> \&listener_start,
            _stop	=> \&listener_stop,
            listener_success	=> \&listener_success,
            listener_failure	=> \&listener_failure,
        },
        heap => { server => $server },
    );
}

sub listener_start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    print "Server startup, opening sockets for listening\n";

    $heap->{listener} = POE::Wheel::SocketFactory->new(
        BindAddress => '0.0.0.0',
        BindPort    => 'ircd',
        Reuse       => 'yes',
        SuccessEvent        => 'listener_success',
        FailureEvent        => 'listener_failure',
    );
}

sub listener_stop {
    my $heap = $_[HEAP];
    print "Server shutdown, cleaning up sockets\n";
    delete $heap->{listener};
}

sub listener_success {
    my ($kernel, $heap, $socket, $address, $port) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $address = inet_ntoa($address);
    print "Socket opened!\n";

    new_peer( $heap->{server}, $socket, $address, $port );
}

sub listener_failure {
    my $heap = $_[HEAP];
    print "Listener failed, deleteing all running sockets\n";
    delete $heap->{listener};
}

###########################################################################
# Peer Handler
# Name: peer

sub new_peer {
  my ($server, $socket, $address, $port) = @_;
  POE::Session->create(
    inline_states => {
        _start          => \&peer_start,
        _stop           => \&peer_stop,
        peer_error      => \&peer_error,
        peer_input      => \&peer_input,
        put             => \&peer_put,
        register_input  => \&register_input,
        reclass         => \&reclass,
    },
    heap => {
        server => $server,
        server_host => $server_host,
    },
    args => [ $socket, $address, $port ],
  );
}

sub peer_start {
    my ($kernel, $heap, $socket, $address, $port) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    print "Peer handler started!\n";

    my $filter = POE::Filter::Stackable->new();
    $filter->push(
        POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
        POE::Filter::IRCD->new(),
    );

    $heap->{'socket_wheel'} = POE::Wheel::ReadWrite->new(
        Handle	=> $socket,
        Driver	=> POE::Driver::SysRW->new(),
        Filter	=> $filter,
        InputEvent	=> 'peer_input',
        ErrorEvent	=> 'peer_error',
    );

    POE::Component::Server::IRC::auth->create($heap);
}

sub peer_stop {
    print "Peer handler stopped\n";
}

sub peer_input {
    my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
    $heap->{input_handler}->($input);
}

sub peer_error {
    my ($heap, $error) = @_[HEAP, ARG0];

    print "There was a wheel error: $error\n";

    delete $heap->{'socket_wheel'};
    delete $heap->{destinations}->{$heap->{nick}};
}

sub register_input {
    my ($heap, $handler) = @_[HEAP, ARG0];

    $heap->{input_handler} = $handler;
}

sub reclass {
    my ($kernel, $heap, $class) = @_[KERNEL, HEAP, ARG0];

    if ($class eq 'client') { #this is not how I want to do it really, just quick code
        POE::Component::Server::IRC::client->create($heap);
    }
}

sub peer_put {
    my ($heap, $packet) = @_[HEAP, ARG0];

    $heap->{socket_wheel}->put($packet)
}

1;
__END__


=head1 NAME

POE::Component::Server::IRC - Perl extension for making a subclassable POE session 
set that comes as close as I can to being an IRC daemon.

=head1 SYNOPSIS

  use POE::Component::Server::IRC;
  POE::Component::Server::IRC->new();
  $poe_kernel->run();

=head1 DESCRIPTION

General framework for creating an IRC daemon. Very very alpha code, structures are
not fully designed, bugs do exist. That said, have fun with it, I hope to upload new
versions often enough.

=head2 EXPORT

Nothing

=head1 AUTHOR

See my CPAN details for an email address (the README or Makefile.PL should contain
this information as well)

Many thanks to:
Rocco Caputo for making POE, and putting up with my pestering.
everyone on #poe and #perl

=head1 SEE ALSO

L<POE>, L<perl>.

=cut
