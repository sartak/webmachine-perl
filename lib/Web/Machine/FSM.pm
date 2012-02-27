package Web::Machine::FSM;
use Moose;

use Sub::Identify qw[ sub_name ];
use Try::Tiny;
use HTTP::Date qw[ str2time ];

use Web::Machine::Util;

sub run {
    my ( $self, $resource ) = @_;

    my $request  = $resource->request;
    my $response = $resource->response;
    my $metadata = {};

    my $state = \&b13;

    try {
        while (1) {
            warn "entering " . sub_name( $state ) . "\n";
            my $result = $state->( $resource, $request, $response, $metadata );
            if ( _is_bad_state( $result ) ) {
                warn "! ERROR with " . ($result || 'undef') . "\n";
                $response->status( 500 );
                $response->body( "Got bad state: " . ($result || 'undef') );
                last;
            }
            elsif ( _is_status_code( $result ) ) {
                warn ".. terminating with " . ${ $result } . "\n";
                $response->status( ${ $result } );
                $resource->finish_request;
                last;
            }
            elsif ( _is_new_state( $result ) ) {
                warn "-> transitioning to " . sub_name( $result ) . "\n";
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
    $resource->service_available == true ? \&b12 : \503;
}

sub b12 {
    my ($resource, $request, $response, $metadata) = @_;
    _include( $request->method, $resource->known_methods ) == true ? \&b11 : \501;
}

sub b11 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->uri_too_long( $request->uri ) == true ? \414 : \&b10;
}

sub b10 {
    my ($resource, $request, $response, $metadata) = @_;
    return \&b9 if _include( $request->method, $resource->allowed_methods );
    $response->header('Allow' => join ", " => @{ $resource->allowed_methods } );
    return \405;
}

sub b9 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->malformed_request == true ? \400 : \&b8;
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
    $resource->forbidden == true ? \403 : \&b6;
}

sub b6 {
    my ($resource, $request, $response, $metadata) = @_;

    my $content_headers = Hash::MultiValue->new;
    $request->headers->scan(sub {
        my ($name, $value) = @_;
        $content_headers->add( $name, $value ) if (lc $name) =~ /^content-/;
    });

    $resource->valid_content_headers( $content_headers ) == true ? \&b5 : \501;
}

sub b5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->known_content_type( $request->content_type ) == true ? \&b4 : \415;
}

sub b4 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->valid_entity_length( $request->content_length ) == true ? \&b3 : \413;
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

    # FIXME: this needs work and is most likely totally wrong.
    if ( my $chosen_type = _choose( $request->header('Accept'), $resource->content_types_provided ) ) {
        $metadata->{'Content-Type'} = $chosen_type;
        return \&d4;
    }

    return \406;
}

sub d4 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Language')) ? \&e5 : \&d5;
}

sub d5 {
    my ($resource, $request, $response, $metadata) = @_;

    # FIXME: this needs work and is most likely totally wrong.
    if ( my $chosen_language = _choose( $request->header('Accept-Language'), $resource->languages_provided ) ) {
        $resource->language_chosen( $chosen_language );
        return \&e4;
    }

    return \406;
}

sub e5 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Charset')) ? \&f6 : \&e6;
}

sub e6 {
    my ($resource, $request, $response, $metadata) = @_;
    # FIXME: this needs work and is most likely totally wrong.
    _choose( $request->header('Accept-Charset'), $resource->charsets_provided ) ? \&f6 : \406;
}

sub f6 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Encoding')) ? \&g7 : \&f7;
}

sub f7 {
    my ($resource, $request, $response, $metadata) = @_;
    # FIXME: this needs work and is most likely totally wrong.
    _choose( $request->header('Accept-Encoding'), $resource->encodings_provided ) ? \&g7 : \406;
}

sub g7 {
    my ($resource, $request, $response, $metadata) = @_;
    # TODO: Need to add the Vary header setting stuff here ...
    $resource->resource_exists == true ? \&g8 : \&h7;
}

sub g8 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Match') ? \&g9 : \&h10;
}

sub g9 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Match') eq "*" ? \&h10 : \&g11;
}

sub g11 {
    my ($resource, $request, $response, $metadata) = @_;
    _choose( $resource->generate_etag, [ split /\s*\,\s*/ => $request->header('If-Match') ] ) ? \&h10 : \412;
}

sub h7 {
    my ($resource, $request, $response, $metadata) = @_;
    ($request->header('If-Match') && $request->header('If-Match') == "*") ? \412 : \&i7;
}

sub h10 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Unmodified-Since') ? \&h11 : \&i12;
}

sub h11 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $date = str2time( $request->header('If-Unmodified-Since') ) ) {
        $metadata->{'If-Unmodified-Since'} = $date;
        return \&h12;
    }
    return \&i12;
}

sub h12 {
    my ($resource, $request, $response, $metadata) = @_;
    (defined $resource->last_modified && str2time( $resource->last_modified ) > $metadata->{'If-Unmodified-Since'}) ? \412 : \&i12;
}

sub i4 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $uri = $resource->moved_permanently ) {
        $response->header('Location' => $uri );
        return \301;
    }
    return \&p3;
}

sub i7 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'PUT' ? \&i4 : \&k7
}

sub i12 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-None-Match') ? \&i13 : \&l13
}

sub i13 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-None-Match') eq "*" ? \&j13 : \&k13
}

sub j18 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'GET' || $request->method eq 'HEAD' ? \304 : \412
}

sub k5 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $uri = $resource->moved_permanently ) {
        $response->header('Location' => $uri );
        return \301;
    }
    return \&l5;
}

sub k7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->previously_existed == true ? \&k5 : \&l7;
}

sub k13 {
    my ($resource, $request, $response, $metadata) = @_;
    _choose( $resource->generate_etag, [ split /\s*\,\s*/ => $request->header('If-Match') ] ) ? \&j18 : \&l13;
}

sub l5 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $uri = $resource->moved_temporarily ) {
        $response->header('Location' => $uri );
        return \307;
    }
    return \&m5;
}

sub l7 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&m7 : \404
}

sub l13 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Modified-Since') ? \&l14 : \&m16
}

sub l14 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $date = str2time( $request->header('If-Modified-Since') ) ) {
        $metadata->{'If-Modified-Since'} = $date;
        return \&l15;
    }
    return \&m16;
}

sub l15 {
    my ($resource, $request, $response, $metadata) = @_;
    ($metadata->{'If-Modified-Since'} > (scalar time)) ? \&m16 : \&l17;
}

sub l17 {
    my ($resource, $request, $response, $metadata) = @_;
    (defined $resource->last_modified && str2time( $resource->last_modified ) > $metadata->{'If-Modified-Since'}) ? \&m16 : \304;
}

sub m5 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&n5 : \410
}

sub m7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->allow_missing_post == true ? \&n11 : \404
}

sub m16 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'DELETE' ? \&m20 : \&n16
}

sub m20 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->delete_resource == true ? \&m20b : \500
}

sub m20b {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->delete_completed == true ? \&o20 : \202
}

sub n5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->allow_missing_post == true ? \&n11 : \410
}

sub n11 {
    die "n11"
}

sub n16 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&n11 : \&o16
}

#  ...

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

# FIXME: this needs work
sub _choose {
    my ($requested, $choices) = @_;
    foreach my $provided ( @$choices ) {
        if ( $provided =~ /$requested/i ) {
            return $provided;
        }
    }
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM;

=head1 DESCRIPTION

