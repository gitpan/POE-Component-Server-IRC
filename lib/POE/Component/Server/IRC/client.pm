package POE::Component::Server::IRC::client;

use strict;
use warnings;
use POE;

use Data::Dumper;

use vars qw/$VERSION/;

$VERSION = '0.0001';

sub create {
  my $self = shift;
  my $heap = shift;

  POE::Session->create(
    inline_states => {
      _start        => \&client_start,
      _stop         => \&client_stop,
      client_input  => \&client_input,
      irc_ping      => \&irc_ping,
      irc_mode      => \&irc_mode,
      irc_privmsg   => \&irc_privmsg,
      irc_quit      => \&irc_quit,
    }, heap => $heap
  );
}

sub client_start {
  my ($kernel, $session, $heap, $sender) = @_[KERNEL, SESSION, HEAP, SENDER];
  $heap->{parent} = $sender;
  $kernel->call($sender, 'register_input', $session->postback('client_input'));
  print "Client handler started!\n";
}

sub client_stop {
  print "Client handler stopped!\n";
}

sub client_input {
  my ($kernel, $session, $arg1) = @_[KERNEL, SESSION, ARG1];
  my $buf = $arg1->[0];
  $kernel->call( $session, 'irc_' . lc($buf->{'command'}), $buf );
}

sub irc_ping {
  my ($kernel, $heap, $buf) = @_[KERNEL, HEAP, ARG0];

  $kernel->call($heap->{parent}, 'put', {
    prefix	=> 'ryoko',
    command	=> 'PONG',
    params	=> [ $buf->{params}->[0] ],
  });
}

sub irc_mode {
  my ($kernel, $heap, $buf) = @_[KERNEL, HEAP, ARG0];

  $kernel->call($heap->{parent}, 'put', {
    prefix     => 'ryoko',
    command    => 'MODE',
    params     => $buf->{params},
  });
}

sub irc_privmsg {
    my ($kernel, $heap, $buf) = @_[KERNEL, HEAP, ARG0];

    foreach my $recipient (split /,/, $buf->{params}->[0]) {
        $heap->{server}->nick_lookup($recipient)->({
            prefix  => $heap->{nick},
            command => 'PRIVMSG',
            params  => $buf->{params},
        });
    }
}

sub irc_quit {
    my ($kernel, $heap, $buf) = @_[KERNEL, HEAP, ARG0];

    $heap->{server}->nick_delete($heap->{nick});
    $kernel->call($heap->{parent}, 'register_input', undef, undef);
}


# STUB!!!
sub auth_irc_nick {
  my ($kernel, $session, $heap, $buf) = @_[KERNEL, SESSION, HEAP, ARG0];
  my $params = $buf->{params};
  my $nicks = $heap->{nicks};

  if (exists $nicks->{lc($params->[0])} ) {
    $kernel->call($heap->{parent}, 'put', {
      prefix    => $heap->{server_host},
      command   => '433',
      params    => [ $params->[0], "Nickname is already in use."],
    });
  } else {
    $heap->{nick} = $params->[0];
    $heap->{nicks}->{$params->[0]} = 0;
    $kernel->call($heap->{parent}, 'put', {
      prefix    => $heap->{server_host},
      command   => 'NICK'
    });
  }
}


1;
__END__


=head1 NAME

POE::Component::Server::IRC::client - PoCo::Server::IRC framework component.

=head1 SYNOPSIS

  use POE::Component::Server::IRC::client;
  my $client_handler = POE::Component::Server::IRC::client->new();

=head1 DESCRIPTION

This module implements a general client connection under the PoCo::Server::IRC
framework. This structures are not concrete yet, please note the version number and
it's miniscule size.

=head2 EXPORT

Nothing

=head1 AUTHOR

hachi, see CPAN for contact details (or the readme, or things like that)

=head1 SEE ALSO

L<POE>, L<perl>.

=cut
