
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A fully event-driven networkable IRC server daemon module.',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>',
  'BUILD_REQUIRES' => {
    'POE::Component::IRC' => '5.70',
    'Test::More' => '0.47'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'POE-Component-Server-IRC',
  'EXE_FILES' => [
    'bin/pmkpasswd'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'POE::Component::Server::IRC',
  'PREREQ_PM' => {
    'Algorithm::Diff' => '1.19',
    'Crypt::PasswdMD5' => '1.3',
    'Date::Format' => '0',
    'Net::Netmask' => '1.9012',
    'Object::Pluggable' => '1.29',
    'POE' => '0.9999',
    'POE::Component::Client::DNS' => '1.00',
    'POE::Component::Client::Ident' => '1.00',
    'POE::Filter::IRCD' => '2.2',
    'constant' => '1.17'
  },
  'VERSION' => '1.41',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



