package Web::Machine::Util::PriorityList;
# ABSTRACT: A Priority List

use strict;
use warnings;

use Web::Machine::Util qw[ split_header_words ];

sub new { bless { 'index' => {}, 'items' => {} } => (shift) }

sub index { (shift)->{'index'} }
sub items { (shift)->{'items'} }

sub new_from_header_string {
    my ($class, $header_string) = @_;
    my $list = $class->new;
    foreach my $header ( split_header_words( $header_string ) ) {
        $list->_add_header_value( $header );
    }
    $list;
}

sub add {
    my ($self, $q, $choice) = @_;
    $self->index->{ $choice } = $q;
    $self->items->{ $q } = [] unless exists $self->items->{ $q };
    push @{ $self->items->{ $q } } => $choice;
}

sub _add_header_value {
    my $self = shift;
    my ($choice, %params) = @{ $_[0] };
    $self->add( $params{'q'} || 1.0, $choice );
}

sub get {
    my ($self, $q) = @_;
    $self->items->{ $q };
}

sub priority_of {
    my ($self, $choice) = @_;
    $self->index->{ $choice };
}

sub iterable {
    my $self = shift;
    map {
        my $q = $_;
        map { [ $q, $_ ] } @{ $self->items->{ $q } }
    } reverse sort keys %{ $self->items };
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util::PriorityList;

=head1 DESCRIPTION

This is a simple priority list implementation.

=head1 METHODS

=item C<new>

=item C<new_from_header_string ( @header_list )>

This accepts a list of HTTP header values which
get parsed and loaded accordingly.

=item C<index>

=item C<items>

=item C<add ( $quality, $choice )>

Add in a new C<$choice> with a given C<$quality>.

=item C<get ( $quality )>

Given a certain C<$quality>, it returns the various
choices available.

=item C<priority_of ( $choice )>

Given a certain C<$choice> this returns the associated
quality of it.

=item C<iterable>

This returns a list of two item ARRAY refs with the
quality as the first item and the associated choice
as the second item. These are sorted accordingly.

=back



