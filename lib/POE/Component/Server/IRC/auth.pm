package POE::Component::Server::IRC::auth;

use strict;
use warnings;
use POE;

use vars qw/$VERSION/;

$VERSION = '0.0001';

sub create {
  my $self = shift;
  my $heap = shift;
  POE::Session->create(
    inline_states => {
      _start        => \&auth_start,
      _stop         => \&auth_stop,
      auth_input    => \&auth_input,
      irc_pass      => \&auth_irc_pass,
      irc_nick      => \&auth_irc_nick,
      irc_user      => \&auth_irc_user,
      irc_quit      => \&auth_irc_quit,
      check_auth    => \&auth_check_auth,
    }, 
    heap => $heap,
  );
}

sub auth_start {
  my ($kernel, $session, $heap, $sender) = @_[KERNEL, SESSION, HEAP, SENDER];
  $heap->{parent} = $sender;
  $kernel->call($sender, 'register_input', $session->postback('auth_input'));
  print "Auth handler started!\n";
}

sub auth_stop {
  print "Auth handler stopped!\n";
}

sub auth_input {
  my ($kernel, $session, $arg1) = @_[KERNEL, SESSION, ARG1];
  my $buf = $arg1->[0];
  $kernel->call( $session, 'irc_' . lc($buf->{'command'}), $buf );
}

sub auth_irc_pass {
  my ($heap, $buf) = @_[HEAP, ARG0];
}

sub auth_irc_nick {
  my ($kernel, $session, $heap, $buf) = @_[KERNEL, SESSION, HEAP, ARG0];
  my $params = $buf->{params};

  if ( $heap->{server}->nick_exists($params->[0]) ) {
    $kernel->call($heap->{parent}, 'put', {
      prefix    => $heap->{server_host},
      command   => '433',
      params    => [ $params->[0], "Nickname is already in use."],
    });
  } else {
    $heap->{nick} = $params->[0];
    $heap->{server}->nick_reserve($params->[0]);
  }

  $kernel->call($session, 'check_auth');
}

sub auth_irc_user {
  my ($kernel, $session, $heap, $buf) = @_[KERNEL, SESSION, HEAP, ARG0];

  $heap->{username} = $buf->{params}->[0];
  $heap->{realname} = $buf->{params}->[3];

  $kernel->call($session, 'check_auth');
}

sub auth_check_auth {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  if ($heap->{nick} && $heap->{username}) {
    $kernel->call($heap->{parent}, 'put', {
      prefix    => $heap->{server_host},
      command   => '001',
      params    => [$heap->{nick}, "Welcome to POEIRCD $heap->{nick}!"],
    });
    $kernel->call($heap->{parent}, 'put', {
      prefix    => $heap->{server_host},
      command   => '002',
      params    => [$heap->{nick}, "Your host is $heap->{server_host}"],
    });

    $heap->{server}->nick_unreserve($heap->{nick});
    $heap->{server}->nick_add($heap->{nick}, sub { $kernel->call($heap->{parent}, 'put', @_) } );
    $kernel->call($heap->{parent}, 'reclass', 'client');
  }
}

sub auth_irc_quit {
  my $heap = $_[HEAP];
  $heap->{server}->delete_nick($heap->{nick});
}

1;
__END__


=head1 NAME

POE::Component::Server::IRC - PoCo::Server::IRC module for initial authorization.

=head1 SYNOPSIS

  use POE::Component::Server::IRC::auth;
  my $auth_handler = POE::Component::Server::IRC::auth->new(
      ClientHandler => $client_handler,
      ServerHandler => $server_handler,
      ServiceHandler => $service_handler,
  );

=head1 DESCRIPTION

This module handles the generic authorization process of of PoCo::Server::IRC. The
structures are /not/ set in concrete yet, just look at the version number and this
should clue you in on how unfinished this is yet.

=head2 EXPORT

Nothing

=head1 AUTHOR

hachi (see CPAN listings for email)

=head1 SEE ALSO

L<POE>, L<perl>.

=cut
