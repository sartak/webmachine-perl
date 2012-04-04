package Web::Machine::Util::MediaTypeList;
# ABSTRACT: A Priority List customized for Media Types

use strict;
use warnings;

use parent 'Web::Machine::Util::PriorityList';

sub add_header_value {
    my ($self, $c) = @_;
    my $mt = Web::Machine::Util::MediaType->new_from_string( $c );
    # NOTE:
    # we delete the q param here because we
    # do not want it to be involved in the
    # matching of the params.
    # - SL
    my $q  = $mt->remove_param( 'q' ) || 1.0;
    $self->add( $q, $mt );
}

sub iterable {
    my $self = shift;
    # From RFC-2616 sec14
    # Media ranges can be overridden by more specific
    # media ranges or specific media types. If more
    # than one media range applies to a given type,
    # the most specific reference has precedence.
    sort {
        if ( $a->[0] == $b->[0] ) {
            $a->[1]->matches_all
                ? 1
                : ($b->[1]->matches_all
                    ? -1
                    : ($a->[1]->minor eq '*'
                        ? 1
                        : ($b->[1]->minor eq '*'
                            ? -1
                            : ($a->[1]->params_are_empty
                                ? 1
                                : ($b->[1]->params_are_empty
                                    ? -1
                                    : 0)))))
        }
        else {
            $b->[0] <=> $a->[0]
        }
    } map {
        my $q = $_;
        map { [ $q+0, $_ ] } reverse @{ $self->items->{ $q } }
    } keys %{ $self->items };
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util::MediaTypeList;

=head1 DESCRIPTION

This is a subclass of the L<Web::Machine::Util::PriorityList>
class with some specific media-type features.

=head1 METHODS

=over 4

=item C<add_header_value ( $header )>

This completely overrides the parent method and uses the
L<Web::Machine::Util::MediaType> to parse the C<$header>
and extract data on the quality.

=item C<iterable>

This returns the same data type as the parent (two element
ARRAY ref with quality and choice), but the choice element
will be a L<Web::Machine::Util::MediaType> object. This is
also sorted in a very specific manner in order to align with
RFC-2616 Sec14.

  Media ranges can be overridden by more specific
  media ranges or specific media types. If more
  than one media range applies to a given type,
  the most specific reference has precedence.

=back




