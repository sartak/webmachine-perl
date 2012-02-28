package Web::Machine::Util::MediaType;
use Moose;

use Syntax::Keyword::Junction qw[ any ];

our $MEDIA_TYPE_REGEX = qr/^\s*([^;\s]+)\s*((?:;\s*\S+\s*)*)\s*$/;
our $PARAMS_REGEX     = qr/;\s*([^=]+)=([^;=\s]+)/;

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'params' => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    handles  => {
        'params_are_empty' => 'is_empty'
    }
);

sub new_from_string {
    my ($class, $media_type) = @_;
    if ( $media_type =~ /$MEDIA_TYPE_REGEX/ ) {
        my ($type, $raw_params) = ($1, $2);
        my %params = ($raw_params =~ /$PARAMS_REGEX/);
        return $class->new( type => $type, params => \%params );
    }
    confess "Unable to parse media type from '$media_type'"
}

sub major { (split '/' => (shift)->type)[0] }
sub minor { (split '/' => (shift)->type)[1] }

sub to_string {
    my $self = shift;
    join ';' => $self->type, map { join '=' => $_, $self->params->{ $_ } } keys %{ $self->params };
}

sub matches_all {
    my $self = shift;
    $self->type eq '*/*' && $self->params_are_empty
        ? 1 : 0;
}

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
    return 1 if any('*', '*/*', $self->type) eq $other->type;
    $other->major eq $self->major && $other->minor eq '*'
        ? 1 : 0;
}

sub params_match {
    my ($self, $other) = @_;
    my $params = $self->params;
    foreach my $k ( keys %$other ) {
        return 0 unless exists $params->{ $k } && $params->{ $k } eq $other->{ $k };
    }
    return 1;
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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Util::MediaType;

=head1 DESCRIPTION

