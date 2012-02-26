package Web::Machine::Util;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use JSON::XS    ();
use Sub::Exporter;

my @exports = qw/
    true
    false
    is_bool
/;

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

sub true  () { JSON::XS::true()           }
sub false () { JSON::XS::false()          }
sub is_bool  { JSON::XS::is_bool( shift ) }


1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Util;

=head1 DESCRIPTION

