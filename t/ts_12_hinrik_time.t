use Test::More tests => 17;
BEGIN { use_ok('POE::Component::Server::IRC') };
BEGIN { use_ok('POE::Component::IRC') };
BEGIN { use_ok('POE') };

my $pocosi = POE::Component::Server::IRC->spawn( auth => 0, options => { trace => 0 }, antiflood => 0, plugin_debug => 0, debug => 0 );
my $pocoirc = POE::Component::IRC->spawn( flood => 1, debug => 0 );

if ( $pocosi and $pocoirc ) {
	isa_ok( $pocosi, "POE::Component::Server::IRC" );
	POE::Session->create(
		package_states => [ 
			'main' => [ qw( _start 
					_shutdown
					_default	
					irc_001
					irc_422
					irc_391
					ircd_registered
					ircd_daemon_nick
					ircd_listener_add
					ircd_listener_del) ],
		],
		options => { trace => 0 },
		heap => { irc => $pocoirc, ircd => $pocosi },
	);
	$poe_kernel->run();
}

exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  $heap->{irc}->yield( 'register' => 'all' );
  $heap->{ircd}->yield( 'register' );
  $heap->{ircd}->add_listener();
  $kernel->delay( '_shutdown' => 20 );
  undef;
}

sub _shutdown {
  my $heap = $_[HEAP];
  $_[KERNEL]->delay( '_shutdown' => undef );
  $heap->{irc}->yield( 'unregister' => 'all' );
  $heap->{irc}->yield( 'shutdown' );
  $heap->{ircd}->yield( 'shutdown' );
  delete $heap->{irc}; delete $heap->{ircd};
  undef;
}

sub ircd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  my $backend = $_[SENDER]->get_heap();
  isa_ok( $object, "POE::Component::Server::IRC" );
  isa_ok( $backend, "POE::Component::Server::IRC" );
  undef;
}

sub ircd_listener_add {
  my ($heap,$port) = @_[HEAP,ARG0];
  ok( 1, "Started a listener on $port" );
  $heap->{port} = $port;
  $heap->{irc}->yield( connect => { server => 'localhost', port => $port, nick => 'Moo' } );
  undef;
}

sub ircd_listener_del {
  my ($heap,$port) = @_[HEAP,ARG0];
  ok( 1, "Stopped listener on $port" );
  $_[KERNEL]->yield( '_shutdown' );
  undef;
}

sub ircd_backend_connection {
  ok( 1, 'ircd_backend_connection' );
  undef;
}

sub ircd_backend_auth_done {
  ok( 1, 'ircd_backend_auth_done' );
  undef;
}

sub ircd_daemon_nick {
  ok( 1, 'ircd_daemon_nick ' . $_[ARG0] );
  undef;
}

sub ircd_backend_cmd_user {
  ok( 1, 'ircd_backend_cmd_user' );
  undef;
}

sub irc_001 {
  pass("irc_001");
  $poe_kernel->post( $_[SENDER], 'time' );
  undef;
}

sub irc_391 {
  pass("irc_391");
  $poe_kernel->yield('_shutdown');
  return;
}

sub irc_422 {
  return if $_[HEAP]->{422};
  pass("irc_422");
  $_[HEAP]->{422}++;
  return;
}

sub _default {
  my $event = $_[ARG0];
  if ( $event =~ /^irc_(00[1234]|25[15]|323)/ or $event eq 'irc_isupport' ) {
	ok( 1, $event );
  }
  if ( $event eq 'irc_error' ) {
	ok( 1, $event );
	$_[HEAP]->{ircd}->del_listener( port => $_[HEAP]->{port} );
  }
  undef;
}