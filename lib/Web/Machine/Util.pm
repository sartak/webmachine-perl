package Web::Machine::Util;

use strict;
use warnings;

use List::Util qw[ first ];
use HTTP::Date qw[ str2time ];

use Sub::Exporter -setup => {
    exports => [qw[
        first
        any
        includes
        str2time
        pair_key
        pair_value
    ]]
};

sub pair_key   { ( keys   %{ $_[0] } )[0] }
sub pair_value { ( values %{ $_[0] } )[0] }

sub any (&@) { my $f = shift; $f->() && return 1 for @_; 0 }

sub includes {
    my ($value, $list) = @_;
    (any { $_ eq $value } @$list) && return 1; 0
}

1;

__END__

# ABSTRACT: General Utility module

=head1 SYNOPSIS

  use Web::Machine::Util;

=head1 DESCRIPTION

