package Web::Machine::Util::MediaTypeList;
use Moose;

use Web::Machine::Util::MediaType;

extends 'Web::Machine::Util::PriorityList';

sub add_header_value {
    my ($self, $c) = @_;
    my $mt = Web::Machine::Util::MediaType->new_from_string( $c );
    my $q  = delete $mt->params->{ 'q' } || 1.0;
    $self->add( $q, $mt );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Util::MediaTypeList;

=head1 DESCRIPTION

