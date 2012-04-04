package Web::Machine::Util::PriorityList;
# ABSTRACT: A Priority List

use strict;
use warnings;

sub new { bless { 'index' => {}, 'items' => {} } => (shift) }

sub index { (shift)->{'index'} }
sub items { (shift)->{'items'} }

sub new_from_header_list {
    my ($class, @header_list) = @_;
    my $list = $class->new;
    foreach my $header ( @header_list ) {
        $list->add_header_value( $header );
    }
    $list;
}

sub add {
    my ($self, $q, $choice) = @_;
    $self->index->{ $choice } = $q;
    $self->items->{ $q } = [] unless exists $self->items->{ $q };
    push @{ $self->items->{ $q } } => $choice;
}

sub add_header_value {
    my ($self, $c) = @_;
    if ( $c =~ /^\s*(\S+);\s*q=(\S*)\s*$/ ) {
        my ($choice, $q) = ($1, $2);
        $self->add( $q, $choice );
    }
    else {
        $self->add( 1.0, $c );
    }
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

=item C<new_from_header_list ( @header_list )>

This accepts a list of HTTP header values which
each get passed to C<add_header_value>

=item C<index>

=item C<items>

=item C<add ( $quality, $choice )>

Add in a new C<$choice> with a given C<$quality>.

=item C<add_header_value ( $header_value )>

This accepts an HTTP header value and parses out
the quality and choice accordingly.

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



