package Web::Machine::FSM::States;

use strict;
use warnings;

use List::MoreUtils qw[ any ];
use HTTP::Date      qw[ str2time ];

use Web::Machine::Util::MediaType;
use Web::Machine::Util::ContentNegotiation qw[
    choose_media_type
    choose_language
    choose_charset
    choose_encoding
];

use Sub::Exporter -setup => {
    exports => [qw[
        start_state
        is_status_code
        is_new_state
        get_state_name
    ]]
};

sub start_state    { \&b13 }
sub is_status_code { ref $_[0] eq 'SCALAR' }
sub is_new_state   { ref $_[0] eq 'CODE'   }
sub get_state_name { B::svref_2object( shift )->GV->NAME }

sub _include {
    my ($value, $list) = @_;
    return 1 if any { $_ eq $value } @$list;
    return 0;
}

sub _unquote_header {
    my $value = shift;
    if ( $value = /^"(.*)"$/ ) {
        return $1;
    }
    return $value;
}

## States

# Service available?
sub b13 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->service_available ? \&b12 : \503;
}

# Known method?
sub b12 {
    my ($resource, $request, $response, $metadata) = @_;
    _include( $request->method, $resource->known_methods ) ? \&b11 : \501;
}

# URI too long?
sub b11 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->uri_too_long( $request->uri ) ? \414 : \&b10;
}

# Method allowed?
sub b10 {
    my ($resource, $request, $response, $metadata) = @_;
    return \&b9 if _include( $request->method, $resource->allowed_methods );
    $response->header('Allow' => join ", " => @{ $resource->allowed_methods } );
    return \405;
}

# Malformed?
sub b9 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->malformed_request ? \400 : \&b8;
}

# Authorized
sub b8 {
    my ($resource, $request, $response, $metadata) = @_;
    my $result = $resource->is_authorized( $request->header('Authorization') );
    # if we get back a status, then use it
    if ( is_status_code( $result ) ) {
        return $result;
    }
    # if we just get back true, then
    # move onto the next state
    elsif ( "$result" eq "1" ) {
        return \&b7
    }
    # anything else will either be
    # a WWW-Authenticate header or
    # a simple false value
    else {
        if ( $result ) {
            $response->header( 'WWW-Authenticate' => $result );
        }
        return \401;
    }
}

# Forbidden?
sub b7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->forbidden ? \403 : \&b6;
}

# Okay Content-* Headers?
sub b6 {
    my ($resource, $request, $response, $metadata) = @_;

    my $content_headers = Hash::MultiValue->new;
    $request->headers->scan(sub {
        my ($name, $value) = @_;
        $content_headers->add( $name, $value ) if (lc $name) =~ /^content-/;
    });

    $resource->valid_content_headers( $content_headers ) ? \&b5 : \501;
}

# Known Content-Type?
sub b5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->known_content_type( $request->content_type ) ? \&b4 : \415;
}

# Request Entity too Large?
sub b4 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->valid_entity_length( $request->content_length ) ? \&b3 : \413;
}

# OPTIONS?
sub b3 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( $request->method eq 'OPTIONS' ) {
        $response->headers( $resource->options );
        return \200;
    }
    return \&c3
}

# Accept exists?
sub c3 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( !$request->header('Accept') ) {
        $metadata->{'Content-Type'} = Web::Machine::Util::MediaType->new_from_string(
            $resource->content_types_provided->[0]->[0]
        );
        return \&d4
    }
    return \&c4;
}

# Acceptable media type available?
sub c4 {
    my ($resource, $request, $response, $metadata) = @_;

    my @types = map { $_->[0] } @{ $resource->content_types_provided };

    if ( my $chosen_type = choose_media_type( \@types, $request->header('Accept') ) ) {
        $metadata->{'Content-Type'} = $chosen_type;
        return \&d4;
    }

    return \406;
}

# Accept-Language exists?
sub d4 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Language')) ? \&e5 : \&d5;
}


# Acceptable language available?
sub d5 {
    my ($resource, $request, $response, $metadata) = @_;

    if ( my $language = choose_language( $resource->languages_provided, $request->header('Accept-Language') ) ) {
        $metadata->{'Language'} = $language;
        $response->header( 'Content-Language' => $language );
        return \&e4;
    }

    return \406;
}

# Accept-Charset exists?
sub e5 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Charset')) ? \&f6 : \&e6;
}

# Acceptable Charset available?
sub e6 {
    my ($resource, $request, $response, $metadata) = @_;

    if ( my $charset = choose_charset( $resource->charsets_provided, $request->header('Accept-Charset') ) ) {
        $metadata->{'Charset'} = $charset;
        return \&f6;
    }

    return \406;
}

# Accept-Encoding exists?
# (also, set content-type header here, now that charset is chosen)
sub f6 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $charset = $metadata->{'Charset'} ) {
        # Add the charset to the content type now ...
        $metadata->{'Content-Type'}->params->{'charset'} = $charset;
    }
    # put the content type in the header now ...
    $response->header( 'Content-Type' => $metadata->{'Content-Type'}->to_string );
    (not $request->header('Accept-Encoding')) ? \&g7 : \&f7;
}

# Acceptable encoding available?
sub f7 {
    my ($resource, $request, $response, $metadata) = @_;

    if ( my $encoding = choose_encoding( $request->header('Accept-Encoding'), $resource->encodings_provided ) ) {
        $response->header( 'Content-Encoding' => $encoding ) unless $encoding eq 'identity';
        $metadata->{'Content-Encoding'} = $encoding;
        return \&g7;
    }

    return \406;
}

# Resource exists?
sub g7 {
    my ($resource, $request, $response, $metadata) = @_;

    # NOTE:
    # set Vary header here since we are
    # done with content negotiation
    # - SL
    my @variances = @{ $resource->variances };

    push @variances => 'Accept'          if @{ $resource->content_types_provided };
    push @variances => 'Accept-Language' if @{ $resource->languages_provided };
    push @variances => 'Accept-Charset'  if @{ $resource->charsets_provided };
    push @variances => 'Accept-Encoding' if keys %{ $resource->encodings_provided };

    $response->header( 'Vary' => join ', ' => @variances ) if @variances;

    $resource->resource_exists ? \&g8 : \&h7;
}

# If-Match exists?
sub g8 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Match') ? \&g9 : \&h10;
}

# If-Match: * exists?
sub g9 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Match') eq "*" ? \&h10 : \&g11;
}

# ETag in If-Match
sub g11 {
    my ($resource, $request, $response, $metadata) = @_;
    my @etags = map { _unquote_header( $_ ) } split /\s*\,\s*/ => $request->header('If-Match');
    _include( $resource->generate_etag, \@etags ) ? \&h10 : \412;
}

# If-Match exists?
sub h7 {
    my ($resource, $request, $response, $metadata) = @_;
    ($request->header('If-Match') && _unquote_header( $request->header('If-Match') ) eq "*") ? \412 : \&i7;
}

# If-Unmodified-Since exists?
sub h10 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Unmodified-Since') ? \&h11 : \&i12;
}

# If-Unmodified-Since is valid date?
sub h11 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $date = str2time( $request->header('If-Unmodified-Since') ) ) {
        $metadata->{'If-Unmodified-Since'} = $date;
        return \&h12;
    }
    return \&i12;
}

# Last-Modified > I-UM-S?
sub h12 {
    my ($resource, $request, $response, $metadata) = @_;
    defined $resource->last_modified
        &&
    (str2time( $resource->last_modified ) > $metadata->{'If-Unmodified-Since'})
        ? \412 : \&i12;
}

# Moved permanently? (apply PUT to different URI)
sub i4 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $uri = $resource->moved_permanently ) {
        if ( is_status_code( $uri ) ) {
            return $uri;
        }
        $response->header('Location' => $uri );
        return \301;
    }
    return \&p3;
}

# PUT?
sub i7 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'PUT' ? \&i4 : \&k7
}

# If-none-match exists?
sub i12 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-None-Match') ? \&i13 : \&l13
}

# If-none-match: * exists?
sub i13 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-None-Match') eq "*" ? \&j13 : \&k13
}

# GET or HEAD?
sub j18 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'GET' || $request->method eq 'HEAD' ? \304 : \412
}

# Moved permanently?
sub k5 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $uri = $resource->moved_permanently ) {
        if ( is_status_code( $uri ) ) {
            return $uri;
        }
        $response->header('Location' => $uri );
        return \301;
    }
    return \&l5;
}

# Previously existed?
sub k7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->previously_existed ? \&k5 : \&l7;
}

# Etag in if-none-match?
sub k13 {
    my ($resource, $request, $response, $metadata) = @_;
    my @etags = map { _unquote_header( $_ ) } split /\s*\,\s*/ => $request->header('If-None-Match');
    _include( $resource->generate_etag, \@etags ) ? \&j18 : \&l13;
}

# Moved temporarily?
sub l5 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $uri = $resource->moved_temporarily ) {
        if ( is_status_code( $uri ) ) {
            return $uri;
        }
        $response->header('Location' => $uri );
        return \307;
    }
    return \&m5;
}

# POST?
sub l7 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&m7 : \404
}

# If-Modified-Since exists?
sub l13 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Modified-Since') ? \&l14 : \&m16
}

# If-Modified-Since is valid date?
sub l14 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $date = str2time( $request->header('If-Modified-Since') ) ) {
        $metadata->{'If-Modified-Since'} = $date;
        return \&l15;
    }
    return \&m16;
}

# If-Modified-Since > Now?
sub l15 {
    my ($resource, $request, $response, $metadata) = @_;
    ($metadata->{'If-Modified-Since'} > (scalar time)) ? \&m16 : \&l17;
}

# Last-Modified > If-Modified-Since?
sub l17 {
    my ($resource, $request, $response, $metadata) = @_;
    defined $resource->last_modified
        &&
    (str2time( $resource->last_modified ) > $metadata->{'If-Modified-Since'})
        ? \&m16 : \304;
}

# POST?
sub m5 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&n5 : \410
}

# Server allows POST to missing resource?
sub m7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->allow_missing_post ? \&n11 : \404
}

# DELETE?
sub m16 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'DELETE' ? \&m20 : \&n16
}

# DELETE enacted immediately? (Also where DELETE is forced.)
sub m20 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->delete_resource ? \&m20b : \500
}

# Did the DELETE complete?
sub m20b {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->delete_completed ? \&o20 : \202
}

# Server allows POST to missing resource?
sub n5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->allow_missing_post ? \&n11 : \410
}

# Redirect?
sub n11 {
    my ($resource, $request, $response, $metadata) = @_;
    # ...
}

# POST?
sub n16 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&n11 : \&o16
}

# Conflict?
sub o14 {
    my ($resource, $request, $response, $metadata) = @_;
    return \409 if $resource->is_conflict;
    #...

}


1;

__END__

=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
