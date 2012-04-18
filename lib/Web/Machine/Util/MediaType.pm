package Web::Machine::Util::MediaType;
# ABSTRACT: A Media Type

use strict;
use warnings;

use Carp                qw[ confess ];
use Scalar::Util        qw[ blessed ];
use HTTP::Headers::Util qw[ split_header_words join_header_words ];

use overload '""' => 'to_string', fallback => 1;

sub new {
    my $class = shift;
    my ($type, @params) = @_;

    confess "You must specify a type" unless $type;
    confess "Params must be an even sized list" unless (((scalar @params) % 2) == 0);

    my @param_order;
    for ( my $i = 0; $i < $#params; $i += 2 ) {
        push @param_order => $params[ $i ];
    }

    bless {
        type        => $type,
        params      => { @params },
        param_order => \@param_order
    } => $class;
}

sub type   { (shift)->{'type'}   }
sub params { (shift)->{'params'} }

sub _param_order { (shift)->{'param_order'} }

sub new_from_string {
    my ($class, $media_type) = @_;

    my ($tokens) = split_header_words( $media_type );

    confess "Unable to parse media type from '$media_type'"
        if defined $tokens->[1];

    my $type = shift @$tokens;
    shift @$tokens; # will be undef
    my @params = @$tokens;

    return $class->new( $type => @params );
}

sub major { (split '/' => (shift)->type)[0] }
sub minor { (split '/' => (shift)->type)[1] }

sub add_param {
    my ($self, $k, $v) = @_;
    $self->params->{ $k } = $v;
    push @{ $self->_param_order } => $k;
}

sub remove_param {
    my ($self, $k) = @_;
    $self->{'param_order'} = [ grep { $_ ne $k } @{ $self->{'param_order'} } ];
    return delete $self->params->{ $k };
}

sub to_string {
    my $self = shift;
    join_header_words(
        $self->type, undef,
        map { $_, $self->params->{ $_ } } @{ $self->_param_order }
    );
}

sub matches_all {
    my $self = shift;
    $self->type eq '*/*' && $self->params_are_empty
        ? 1 : 0;
}

## ...

# must be exactly the same
sub equals {
    my ($self, $other) = @_;
    $other = (ref $self)->new_from_string( $other ) unless blessed $other;
    $other->type eq $self->type && _compare_params( $self->params, $other->params )
        ? 1 : 0;
}

# types must be compatible and params much match exactly
sub exact_match {
    my ($self, $other) = @_;
    $other = (ref $self)->new_from_string( $other ) unless blessed $other;
    $self->type_matches( $other ) && _compare_params( $self->params, $other->params )
        ? 1 : 0;
}

# types must be be compatible and params should align
sub match {
    my ($self, $other) = @_;
    $other = (ref $self)->new_from_string( $other ) unless blessed $other;
    $self->type_matches( $other ) && $self->params_match( $other->params )
        ? 1 : 0;
}

## ...

sub type_matches {
    my ($self, $other) = @_;
    return 1 if $other->type eq '*' || $other->type eq '*/*' || $other->type eq $self->type;
    $other->major eq $self->major && $other->minor eq '*'
        ? 1 : 0;
}

sub params_match {
    my ($self, $other) = @_;
    my $params = $self->params;
    foreach my $k ( keys %$other ) {
        return 0 if not exists $params->{ $k };
        return 0 if $params->{ $k } ne $other->{ $k };
    }
    return 1;
}

sub params_are_empty {
    my $self = shift;
    (scalar keys %{ $self->params }) == 0 ? 1 : 0
}

## ...

sub _compare_params {
    my ($left, $right) = @_;
    my @left_keys  = sort keys %$left;
    my @right_keys = sort keys %$right;

    return 0 unless (scalar @left_keys) == (scalar @right_keys);

    foreach my $i ( 0 .. $#left_keys ) {
        return 0 unless $left_keys[$i] eq $right_keys[$i];
        return 0 unless $left->{ $left_keys[$i] } eq $right->{ $right_keys[$i] };
    }

    return 1;
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util::MediaType;

=head1 DESCRIPTION

This is an object which represents an HTTP media type
defintion.

=head1 METHODS

=over 4

=item C<new( $type, @params )>

A media type is made up of a type name and a set of
ordered parameter pairs.

=item C<type>

Accessor for the type.

=item C<params>

Accessor for the unordered hash-ref of params.

=item C<new_from_string ( $media_type_string )>

This will take an HTTP header media type definition
and parse it into and object.

=item C<major>

The major portion of the media type name.

=item C<minor>

The minor portion of the media type name.

=item C<add_param( $key, $value )>

Add in a parameter, it will be placed at end
very end of the parameter order.

=item C<remove_param( $key )>

Remove a parameter from the media type.

=item C<to_string>

This stringifys the media type respecting the
parameter order.

=item C<matches_all>

A media type matched all if the type is C<*/*>
and if it has no parameters.

=item C<equals ( $media_type | $media_type_string )>

This will attempt to determine if the C<$media_type> is
exactly the same as itself. If given a C<$media_type_string>
it will parse it into an object.

In order for two type to be equal, the types must match
exactly and the parameters much match exactly.

=item C<exact_match ( $media_type | $media_type_string )>

This will attempt to determine if the C<$media_type> is
a match with itself using the C<type_matches> method below.
If given a C<$media_type_string> it will parse it into an
object.

In order for an exact match to occur it the types must
be compatible and the parameters much match exactly.

=item C<match ( $media_type | $media_type_string )>

This will attempt to determine if the C<$media_type> is
a match with itself using the C<type_matches> method and
C<params_match> method below. If given a C<$media_type_string>
it will parse it into an object.

In order for an exact match to occur it the types must
be compatible and the parameters must be a subset.

=item C<type_matches ( $media_type | $media_type_string )>

This will determine type compatability, properly handling
the C<*> types and major and minor elements of the type.

=item C<params_match ( $parameters )>

This determines if the C<$parameters> are a subset of the
invocants parameters.

=item C<params_are_empty>

Returns false if there are no parameters on the invovant.

=back






