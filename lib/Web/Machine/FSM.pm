package Web::Machine::FSM;
use Moose;

use Try::Tiny;
use Web::Machine::Util;

sub run {
    my ( $self, $resource ) = @_;

    my $request  = $resource->request;
    my $response = $resource->response;
    my $metadata = {};

    my $state = \&b13;

    try {
        while (1) {
            my $result = $state->( $resource, $request, $response, $metadata );
            if ( _is_bad_state( $result ) ) {
                $response->status( 500 );
                $response->body( "Got bad state: " . ($result || 'undef') );
                last;
            }
            elsif ( _is_status_code( $result ) ) {
                $response->status( ${ $result } );
                $resource->finish_request;
                last;
            }
            elsif ( _is_new_state( $result ) ) {
                $state = $result;
            }
        }
    } catch {
        $response->status( 500 );
        $response->body( $_ );
    };

    $response;
}

## -- States ------------------------------------------

sub b13 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( $resource->service_available, true, \&b12, \503 );
}

sub b12 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( _include( $request->method, $resource->known_methods ), true, \&b11, \501 );
}

sub b11 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( $resource->uri_too_long( $request->uri ), true, \414, \&b10 );
}

sub b10 {
    my ($resource, $request, $response, $metadata) = @_;
    return \&b9 if _include( $request->method, $resource->allowed_methods );
    $response->header('Allow' => join ", " => @{ $resource->allowed_methods } );
    return \405;
}

sub b9 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( $resource->malformed_request, true, \400, \&b8 );
}

sub b8 {
    my ($resource, $request, $response, $metadata) = @_;
    my $result = $resource->is_authorized( $request->header('Authorization') );
    unless ( ref $result ) {
        $response->header( 'WWW-Authenticate' => $result );
        return \401;
    }
    return \&b7    if is_bool( $result ) && $result;
    return $result if _is_status_code( $result );
    return \401;
}

sub b7 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( $resource->forbidden, true, \403, \&b6 );
}

sub b6 {
    my ($resource, $request, $response, $metadata) = @_;

    my $content_headers = Hash::MultiValue->new;
    $request->headers->scan(sub {
        my ($name, $value) = @_;
        $content_headers->add( $name, $value ) if (lc $name) =~ /^content-/;
    });

    _test( $resource->valid_content_headers( $content_headers ), true, \&b5, \501 );
}

sub b5 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( $resource->known_content_type( $request->content_type ), true, \&b4, \415 );
}

sub b4 {
    my ($resource, $request, $response, $metadata) = @_;
    _test( $resource->valid_entity_length( $request->content_length ), true, \&b3, \413 );
}

sub b3 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( $request->method eq 'OPTIONS' ) {
        $response->headers( $resource->options );
        return \200;
    }
    return \&c3
}

sub c3 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( not $request->header('Accept') ) {
        $metadata->{'Content-Type'} = $resource->content_types_provided->[0];
        return \&d4
    }
    return \&c4;
}

sub c4 {
    my ($resource, $request, $response, $metadata) = @_;

    my $chosen_type;
    my $requested_type = lc $request->header('Accept');
    foreach my $provided_type ( @{ $resource->content_types_provided } ) {
        if ( $provided_type =~ /$requested_type/ ) {
            $chosen_type = $provided_type;
        }
    }

    return \406 if not $chosen_type;

    $metadata->{'Content-Type'} = $chosen_type;
    return \&d4;
}

sub d4 {
    my ($resource, $request, $response, $metadata) = @_;

}

## -- Utils ----------------------------------------

sub _is_status_code {   ref $_[0] eq 'SCALAR' }
sub _is_new_state   {   ref $_[0] eq 'CODE'   }
sub _is_bad_state   { ! ref $_[0]             }

sub _test {
    my ($test, $value, $if_true, $if_false) = @_;
    #warn join ", " => $test, $value, $if_true, $if_false;
    return $if_true if $test == $value;
    return $test    if _is_status_code( $test );
    return $if_false;
}

sub _include {
    my ($value, $list) = @_;
    return true if scalar grep { $_ eq $value } @$list;
    return false;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM;

=head1 DESCRIPTION

