package Web::Machine::FSM::States;

use strict;
use warnings;

use List::AllUtils qw[ any ];
use HTTP::Date     qw[ str2time ];

use Web::Machine::Util;
use Web::Machine::Util::MediaType;
use Web::Machine::Util::ContentNegotiation qw[
    choose_media_type
    choose_language
    choose_charset
];

use Sub::Exporter -setup => {
    exports => [qw[
        start_state
        is_status_code
        is_new_state
    ]]
};

sub start_state    { \&b13 }
sub is_status_code { ref $_[0] eq 'SCALAR' }
sub is_new_state   { ref $_[0] eq 'CODE'   }

sub _include {
    my ($value, $list) = @_;
    return true if any { $_ eq $value } @$list;
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

## States

# Service available?
sub b13 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->service_available == true ? \&b12 : \503;
}

# Known method?
sub b12 {
    my ($resource, $request, $response, $metadata) = @_;
    _include( $request->method, $resource->known_methods ) == true ? \&b11 : \501;
}

# URI too long?
sub b11 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->uri_too_long( $request->uri ) == true ? \414 : \&b10;
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
    $resource->malformed_request == true ? \400 : \&b8;
}

# Authorized
sub b8 {
    my ($resource, $request, $response, $metadata) = @_;
    my $result = $resource->is_authorized( $request->header('Authorization') );
    unless ( ref $result ) {
        $response->header( 'WWW-Authenticate' => $result );
        return \401;
    }
    return \&b7    if is_bool( $result ) && $result;
    return $result if is_status_code( $result );
    return \401;
}

# Forbidden?
sub b7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->forbidden == true ? \403 : \&b6;
}

# Okay Content-* Headers?
sub b6 {
    my ($resource, $request, $response, $metadata) = @_;

    my $content_headers = Hash::MultiValue->new;
    $request->headers->scan(sub {
        my ($name, $value) = @_;
        $content_headers->add( $name, $value ) if (lc $name) =~ /^content-/;
    });

    $resource->valid_content_headers( $content_headers ) == true ? \&b5 : \501;
}

# Known Content-Type?
sub b5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->known_content_type( $request->content_type ) == true ? \&b4 : \415;
}

# Request Entity too Large?
sub b4 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->valid_entity_length( $request->content_length ) == true ? \&b3 : \413;
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

sub o14 {
    my ($resource, $request, $response, $metadata) = @_;
    return \409 if $resource->is_conflict;

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
