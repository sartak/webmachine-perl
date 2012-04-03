package Web::Machine::Util;
# ABSTRACT: General Utility module

use strict;
use warnings;

use List::Util qw[ first ];
use HTTP::Date qw[ str2time ];

use Sub::Exporter -setup => {
    exports => [qw[
        first
        str2time
        pair_key
        pair_value
    ]]
};

sub pair_key   { ( keys   %{ $_[0] } )[0] }
sub pair_value { ( values %{ $_[0] } )[0] }

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util;

=head1 DESCRIPTION

