package Web::Machine::Util::PriorityList;

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

# ABSTRACT: A Priority List

=head1 SYNOPSIS

  use Web::Machine::Util::PriorityList;

=head1 DESCRIPTION

