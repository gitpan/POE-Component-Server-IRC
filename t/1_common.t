use Test::More tests => 26;
BEGIN { use_ok('POE::Component::Server::IRC::Common', qw(:ALL)) }
ok( 'SIMPLE' eq u_irc( 'simple' ), "Upper simple test" );
ok( 'simple' eq l_irc( 'SIMPLE' ), "Lower simple test" );
ok( 'C0MPL~[X]' eq u_irc ( 'c0mpl^{x}' ), "Upper complex test" );
ok( 'c0mpl^{x}' eq l_irc ( 'C0MPL~[X]' ), "Lower complex test" );
my $hashref = parse_mode_line( qw(ov rita bob) );
ok( $hashref->{modes}->[0] eq '+o', "Parse mode test 1" );
ok( $hashref->{args}->[0] eq 'rita', "Parse mode test 2" );
my $hashref2 = parse_mode_line( qw(-b +b!*@*) );
ok( $hashref2->{modes}->[0] eq '-b', "Parse mode test 3" );
ok( $hashref2->{args}->[0] eq '+b!*@*', "Parse mode test 4" );
ok( unparse_mode_line( '+o-v-o-o+v-o+o+o' ) eq '+o-voo+v-o+oo', "Unparse mode test 1" );
my $banmask = parse_ban_mask( 'stalin*' );
ok( $banmask eq 'stalin*!*@*', "Parse ban mask test 1" );
ok( validate_nick_name( 'm00[^]' ), "Nickname is valid test" );
ok( !validate_nick_name( 'm00[=]' ), "Nickname is invalid test" );
ok( validate_chan_name( '#chan.nel' ), "Channel is valid test" );
ok( !validate_chan_name( '#chan,nel' ), "Channel is invalid test" );
ok( matches_mask( '**', '127.0.0.1' ), "Mask matches Test" );
ok( !matches_mask( '127.0.0.2', '127.0.0.1' ), "Mask not matches Test" );
ok( matches_mask( $banmask, 'stalin!joe@kremlin.ru'), "Mask matches Test 2" );
ok( !matches_mask( $banmask, 'BinGOs!joe@kremlin.ru'), "Mask not matches Test 2" );
ok( gen_mode_change('ailowz','i') eq '-alowz', "Gen mode changes 1");
ok( gen_mode_change('i','ailowz') eq '+alowz', "Gen mode changes 2");
ok( gen_mode_change('i','alowz') eq '-i+alowz', "Gen mode changes 3");
my $nick = parse_user('BinGOs!null@fubar.com');
my @args = parse_user('BinGOs!null@fubar.com');
ok( $nick eq 'BinGOs', "Parse User Test 1" );
ok( $nick eq $args[0], "Parse User Test 2" );
ok( $args[1] eq 'null', "Parse User Test 3" );
ok( $args[2] eq 'fubar.com', "Parse User Test 4" );