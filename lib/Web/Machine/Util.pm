package Web::Machine::Util;
# ABSTRACT: General Utility module

use strict;
use warnings;

use Carp       qw[ confess ];
use List::Util qw[ first ];
use HTTP::Date qw[ str2time ];

use Sub::Exporter -setup => {
    exports => [qw[
        first
        str2time
        pair_key
        pair_value
        bind_path
    ]]
};

sub pair_key   { ( keys   %{ $_[0] } )[0] }
sub pair_value { ( values %{ $_[0] } )[0] }

sub bind_path {
    my ($spec, $path) = @_;
    my @parts = split /\// => $path;
    my @spec  = split /\// => $spec;

    my @results;
    foreach my $i ( 0 .. $#spec ) {
        if ( $spec[ $i ] =~ /^\*$/ ) {
            push @results => @parts[ $i .. $#parts ];
            last;
        }
        elsif ( $spec[ $i ] =~ /^\:/ ) {
            (defined $parts[ $i ])
                || confess "Missing part for spec (" . $spec[$i] . ")";
            push @results => $parts[ $i ];
        }
        elsif ( $spec[ $i ] =~ /^\?\:/ ) {
            push @results => $parts[ $i ] if defined $parts[ $i ];
        }
        else {
            (defined $parts[ $i ])
                || confess "Missing part for spec (" . $spec[$i] . ")";
            ($spec[$i] eq $parts[$i])
                || confess "Literal part (" . $parts[$i] . ") did not match spec (" . $spec[$i] . ")";
        }
    }

    @results;
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util;

=head1 DESCRIPTION

This is just a basic utility module used internally by
L<Web::Machine>. There is no real user servicable parts
in here.

=head1 FUNCTIONS

=over 4

=item C<first>

This is imported from L<List::Util> and passed on here
for export.

=item C<str2time>

This is imported from L<HTTP::Date> and passed on here
for export.

=item C<pair_key>

=item C<pair_value>

These two functions are used for fetching the key
and value out of a pair in the L<Web::Machine> internals.
We represent a pair simply as a HASH ref with one key.

=back

