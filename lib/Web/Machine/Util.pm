package Web::Machine::Util;

use strict;
use warnings;

use List::Util      qw[ first ];
use List::MoreUtils qw[ any ];
use HTTP::Date      qw[ str2time ];

use Sub::Exporter -setup => {
    exports => [qw[
        first
        any
        str2time
        pair_key
        pair_value
    ]]
};

sub pair_key   { ( keys   %{ $_[0] } )[0] }
sub pair_value { ( values %{ $_[0] } )[0] }

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Util;

=head1 DESCRIPTION

