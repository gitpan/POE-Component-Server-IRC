package POE::Filter::IRCD;

use vars qw/$VERSION/;

$VERSION = '.0001';

sub PUT_LITERAL () { 1 }

# Probably some other stuff should go here.

my $g = {
  space			=> qr/\x20+/o,
  trailing_space	=> qr/\x20*/o,
};

my $irc_regex = qr/^
  (?:
    \x3a                #  : comes before hand
    (\S+)               #  [prefix]
    $g->{'space'}       #  Followed by a space
  )?                    # but is optional.
  (
    \d{3}|[a-zA-Z]+     #  [command]
  )                     # required.
  (?:
    $g->{'space'}       # Strip leading space off [middle]s
    (                   # [middle]s
      (?:
        [^\x00\x0a\x0d\x20\x3a]
        [^\x00\x0a\x0d\x20]*
      )                 # Match on 1 of these,
      (?:
        $g->{'space'}
        [^\x00\x0a\x0d\x20\x3a]
        [^\x00\x0a\x0d\x20]*
      ){0,13}           # then match on 0-13 of these,
    )
  )?                    # otherwise dont match at all.
  (?:
    $g->{'space'}\x3a   # Strip off leading spacecolon for [trailing]
    ([^\x00\x0a\x0d]*)	# [trailing]
  )?                    # [trailing] is not necessary.
  $g->{'trailing_space'}
$/x;


sub get_options {
  # Nothing here yet... still stubbing out as to how I'm gonna lay this out.
}

sub new {
  my $type = shift;
  my $buffer = '';
  return bless(\$buffer, $type);
}

sub get {
  my ($self, $raw_lines) = @_;
  my $events = [];

  foreach my $raw_line (@$raw_lines) {
      print ">>> $raw_line\n";
    if ( my($prefix, $command, $middles, $trailing) = $raw_line =~ m/$irc_regex/ ) {
      my $event = {};
      $event->{'prefix'} = $prefix if ($prefix);
      $event->{'command'} = uc($command);
      $event->{'params'} = [] if ($middles || $trailing);
      push @{$event->{'params'}}, (split /$g->{'space'}/, $middles) if ($middles);
      push @{$event->{'params'}}, $trailing if ($trailing);
      push @$events, $event;
    } else {
      warn "Recieved line $raw_line that is not IRC protocol\n";
    }
  }
  return $events;
}

sub put {
  my ($self, $events) = @_;
  my $raw_lines = [];

  foreach my $event (@$events) {
    if (ref $event eq 'HASH') {
      if ( PUT_LITERAL || checkargs($event) ) {
        my $raw_line = '';
        $raw_line .= (':' . $event->{'prefix'} . ' ') if (exists $event->{'prefix'});
        $raw_line .= $event->{'command'};
        $event->{'params'}->[-1] =~ s/^/:/
          if (@{$event->{'params'}} && $event->{'params'}->[-1] =~ m/\x20/o);
        $raw_line .= (' ' . join ' ', @{$event->{'params'}}) if ( $event->{'params'} && @{$event->{'params'}});
        print "<<< $raw_line\n";
        push @$raw_lines, $raw_line;
      } else {
        next;
      }
    } else {
      warn "non hashref passed to put()\n";
    }
  }
  return $raw_lines;
}


# This thing is far from correct, dont use it.
sub checkargs {
  warn("Invalid characters in prefix: " . $event->{'prefix'} . "\n")
    if ($event->{'prefix'} =~ m/[\x00\x0a\x0d\x20]/);
  warn("Undefined command passed.\n")
    unless ($event->{'command'} =~ m/\S/o);
  warn("Invalid command: " . $event->{'command'} . "\n")
    unless ($event->{'command'} =~ m/^(?:[a-zA-Z]+|\d{3})$/o);
  foreach $middle (@{$event->{'middles'}}) {
    warn("Invalid middle: $middle\n")
      unless ($middle =~ m/^[^\x00\x0a\x0d\x20\x3a][^\x00\x0a\x0d\x20]*$/);
  }
  warn("Invalid trailing: " . $event->{'trailing'} . "\n")
    unless ($event->{'trailing'} =~ m/^[\x00\x0a\x0d]*$/);
}

1;

__END__

=head1 NAME

POE::Filter::IRCD - POE Filter for general IRC protocol processing.

=head1 SYNOPSIS

  use POE::Filter::IRCD;
    or
  use POE qw/Filter::IRCD/;

  my $filter = POE::Filter::IRCD->new();

=head1 DESCRIPTION

See the POE::Filter docs for general calling conventions, the source should be easy
enough to grok for now. This will soon have many more settings for tunability ;)

=head2 EXPORT

Nothing at all.

=head1 BUGS

Dies a horrible death when you feed it something not covered by the RFCs.

=head1 AUTHOR

hachi, see my CPAN or the README, or the Makefile.PL for contact info

=head1 SEE ALSO

L<perl>, L<POE>.

=cut
