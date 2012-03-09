package Web::Machine::Util::MediaTypeList;

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

# ABSTRACT: A Priority List customized for Media Types

=head1 SYNOPSIS

  use Web::Machine::Util::MediaTypeList;

=head1 DESCRIPTION

