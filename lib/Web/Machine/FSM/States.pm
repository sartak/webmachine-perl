package Web::Machine::FSM::States;

use strict;
use warnings;

use Hash::MultiValue;
use List::Util      qw[ first ];
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

my %STATE_DESC;

sub start_state    { \&b13 }
sub is_status_code { ref $_[0] eq 'SCALAR' }
sub is_new_state   { ref $_[0] eq 'CODE'   }
sub get_state_name { B::svref_2object( shift )->GV->NAME }

# some utilities ...

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

sub _accept_helper {
    my ($resource, $request) = @_;

    my $content_type = Web::Machine::Util::MediaType->new_from_string(
        $request->header('Content-Type') || 'application/octet-stream'
    );

    if ( my $acceptable = first { $content_type->match( $_ ) } @{ $resource->content_types_accepted } ) {
        my $content_type_handler = $acceptable->[1];
        return $resource->$content_type_handler();
    }

    return \415;
}

## States

$STATE_DESC{'b13'} = 'service_available';
sub b13 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->service_available ? \&b12 : \503;
}

$STATE_DESC{'b12'} = 'known_method';
sub b12 {
    my ($resource, $request, $response, $metadata) = @_;
    _include( $request->method, $resource->known_methods ) ? \&b11 : \501;
}

$STATE_DESC{'b11'} = 'uri_too_long';
sub b11 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->uri_too_long( $request->uri ) ? \414 : \&b10;
}

$STATE_DESC{'b10'} = 'method_allowed';
sub b10 {
    my ($resource, $request, $response, $metadata) = @_;
    return \&b9 if _include( $request->method, $resource->allowed_methods );
    $response->header('Allow' => join ", " => @{ $resource->allowed_methods } );
    return \405;
}

$STATE_DESC{'b9'} = 'malformed_request';
sub b9 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->malformed_request ? \400 : \&b8;
}

$STATE_DESC{'b8'} = 'is_authorized';
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

$STATE_DESC{'b7'} = 'forbidden';
sub b7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->forbidden ? \403 : \&b6;
}

$STATE_DESC{'b6'} = 'content_headers_okay';
sub b6 {
    my ($resource, $request, $response, $metadata) = @_;

    my $content_headers = Hash::MultiValue->new;
    $request->headers->scan(sub {
        my ($name, $value) = @_;
        $content_headers->add( $name, $value ) if (lc $name) =~ /^content-/;
    });

    $resource->valid_content_headers( $content_headers ) ? \&b5 : \501;
}

$STATE_DESC{'b5'} = 'known_content_type';
sub b5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->known_content_type( $request->content_type ) ? \&b4 : \415;
}

$STATE_DESC{'b4'} = 'request_entity_too_large';
sub b4 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->valid_entity_length( $request->content_length ) ? \&b3 : \413;
}

$STATE_DESC{'b3'} = 'method_is_options';
sub b3 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( $request->method eq 'OPTIONS' ) {
        $response->headers( $resource->options );
        return \200;
    }
    return \&c3
}

$STATE_DESC{'c3'} = 'accept_header_exists';
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

$STATE_DESC{'c4'} = 'acceptable_media_type_available';
sub c4 {
    my ($resource, $request, $response, $metadata) = @_;

    my @types = map { $_->[0] } @{ $resource->content_types_provided };

    if ( my $chosen_type = choose_media_type( \@types, $request->header('Accept') ) ) {
        $metadata->{'Content-Type'} = $chosen_type;
        return \&d4;
    }

    return \406;
}

$STATE_DESC{'d4'} = 'accept_language_header_exists';
sub d4 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Language')) ? \&e5 : \&d5;
}


$STATE_DESC{'d5'} = 'accept_language_choice_available';
sub d5 {
    my ($resource, $request, $response, $metadata) = @_;

    if ( my $language = choose_language( $resource->languages_provided, $request->header('Accept-Language') ) ) {
        $metadata->{'Language'} = $language;
        $response->header( 'Content-Language' => $language );
        return \&e4;
    }

    return \406;
}

$STATE_DESC{'e5'} = 'accept_charset_exists';
sub e5 {
    my ($resource, $request, $response, $metadata) = @_;
    (not $request->header('Accept-Charset')) ? \&f6 : \&e6;
}

$STATE_DESC{'e5'} = 'accept_charset_choice_available';
sub e6 {
    my ($resource, $request, $response, $metadata) = @_;

    if ( my $charset = choose_charset( $resource->charsets_provided, $request->header('Accept-Charset') ) ) {
        $metadata->{'Charset'} = $charset;
        return \&f6;
    }

    return \406;
}

$STATE_DESC{'f6'} = 'accept_encoding_exists';
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

$STATE_DESC{'f7'} = 'accept_encoding_choice_available';
sub f7 {
    my ($resource, $request, $response, $metadata) = @_;

    if ( my $encoding = choose_encoding( $request->header('Accept-Encoding'), $resource->encodings_provided ) ) {
        $response->header( 'Content-Encoding' => $encoding ) unless $encoding eq 'identity';
        $metadata->{'Content-Encoding'} = $encoding;
        return \&g7;
    }

    return \406;
}

$STATE_DESC{'g7'} = 'resource_exists';
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

$STATE_DESC{'g8'} = 'if_match_exists';
sub g8 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Match') ? \&g9 : \&h10;
}

$STATE_DESC{'g9'} = 'if_match_is_wildcard';
sub g9 {
    my ($resource, $request, $response, $metadata) = @_;
    _unquote_header( $request->header('If-Match') ) eq "*" ? \&h10 : \&g11;
}

$STATE_DESC{'g11'} = 'etag_in_if_match_list';
sub g11 {
    my ($resource, $request, $response, $metadata) = @_;
    my @etags = map { _unquote_header( $_ ) } split /\s*\,\s*/ => $request->header('If-Match');
    _include( $resource->generate_etag, \@etags ) ? \&h10 : \412;
}

$STATE_DESC{'h7'} = 'if_match_exists_and_if_match_is_wildcard';
sub h7 {
    my ($resource, $request, $response, $metadata) = @_;
    ($request->header('If-Match') && _unquote_header( $request->header('If-Match') ) eq "*") ? \412 : \&i7;
}

$STATE_DESC{'h10'} = 'if_unmodified_since_exists';
sub h10 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Unmodified-Since') ? \&h11 : \&i12;
}

$STATE_DESC{'h11'} = 'if_unmodified_since_is_valid_date';
sub h11 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $date = str2time( $request->header('If-Unmodified-Since') ) ) {
        $metadata->{'If-Unmodified-Since'} = $date;
        return \&h12;
    }
    return \&i12;
}

$STATE_DESC{'h12'} = 'last_modified_is_greater_than_if_unmodified_since';
sub h12 {
    my ($resource, $request, $response, $metadata) = @_;
    defined $resource->last_modified
        &&
    (str2time( $resource->last_modified ) > $metadata->{'If-Unmodified-Since'})
        ? \412 : \&i12;
}

$STATE_DESC{'i4'} = 'moved_permanently';
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

$STATE_DESC{'i7'} = 'method_is_put';
sub i7 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'PUT' ? \&i4 : \&k7
}

$STATE_DESC{'i12'} = 'if_none_match_exists';
sub i12 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-None-Match') ? \&i13 : \&l13
}

$STATE_DESC{'i13'} = 'if_none_match_is_wildcard';
sub i13 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-None-Match') eq "*" ? \&j13 : \&k13
}

$STATE_DESC{'j18'} = 'method_is_get_or_head';
sub j18 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'GET' || $request->method eq 'HEAD' ? \304 : \412
}

$STATE_DESC{'k5'} = 'moved_permanently';
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

$STATE_DESC{'k7'} = 'previously_existed';
sub k7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->previously_existed ? \&k5 : \&l7;
}

$STATE_DESC{'k13'} = 'etag_in_if_none_match';
sub k13 {
    my ($resource, $request, $response, $metadata) = @_;
    my @etags = map { _unquote_header( $_ ) } split /\s*\,\s*/ => $request->header('If-None-Match');
    _include( $resource->generate_etag, \@etags ) ? \&j18 : \&l13;
}

$STATE_DESC{'l5'} = 'moved_temporarily';
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

$STATE_DESC{'l7'} = 'method_is_post';
sub l7 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&m7 : \404
}

$STATE_DESC{'l13'} = 'if_modified_since_exists';
sub l13 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->header('If-Modified-Since') ? \&l14 : \&m16
}

$STATE_DESC{'l14'} = 'if_modified_since_is_valid_date';
sub l14 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( my $date = str2time( $request->header('If-Modified-Since') ) ) {
        $metadata->{'If-Modified-Since'} = $date;
        return \&l15;
    }
    return \&m16;
}

$STATE_DESC{'l15'} = 'if_modified_since_greater_than_now';
sub l15 {
    my ($resource, $request, $response, $metadata) = @_;
    ($metadata->{'If-Modified-Since'} > (scalar time)) ? \&m16 : \&l17;
}

$STATE_DESC{'l17'} = 'last_modified_is_greater_than_if_modified_since';
sub l17 {
    my ($resource, $request, $response, $metadata) = @_;
    defined $resource->last_modified
        &&
    (str2time( $resource->last_modified ) > $metadata->{'If-Modified-Since'})
        ? \&m16 : \304;
}

$STATE_DESC{'m5'} = 'method_is_post';
sub m5 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&n5 : \410
}

$STATE_DESC{'m7'} = 'allow_post_to_missing_resource';
sub m7 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->allow_missing_post ? \&n11 : \404
}

$STATE_DESC{'m16'} = 'method_is_delete';
sub m16 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'DELETE' ? \&m20 : \&n16
}

$STATE_DESC{'m20'} = 'delete_enacted_immediately';
sub m20 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->delete_resource ? \&m20b : \500
}

$STATE_DESC{'m20b'} = 'did_delete_complete';
sub m20b {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->delete_completed ? \&o20 : \202
}

$STATE_DESC{'n5'} = 'allow_post_to_missing_resource';
sub n5 {
    my ($resource, $request, $response, $metadata) = @_;
    $resource->allow_missing_post ? \&n11 : \410
}

$STATE_DESC{'n11'} = 'redirect';
sub n11 {
    my ($resource, $request, $response, $metadata) = @_;
    if ( $resource->post_is_create ) {
        my $uri = $resource->create_path;
        confess "Create Path Nil" unless $uri;
        my $base_uri = $resource->base_uri || $request->base;
        my $new_uri  = URI->new( $base_uri . $uri );
        # NOTE:
        # the ruby and JS versions will set the path_info
        # for the request object here, but since our requests
        # are immutable, we don't allow that. I don't see
        # where this ends up being useful so I am going to
        # skip it and not bother.
        # - SL
        $response->header( 'Location' => $new_uri->as_string );

        my $result = _accept_helper( $resource, $request );

        return $result if is_status_code( $result );
    }
    else {
        my $result = $resource->process_post;
        if ( $result ) {
            return $result if is_status_code( $result );
            _encode_body_if_set;
        }
        else {
            confess "Process Post Invalid";
        }
    }

    if ( $response->is_redirect ) {
        if ( $response->header( 'Location ') ) {
            return \303;
        }
        else {
            confess "Bad Redirect";
        }
    }

    return \&p11;
}

$STATE_DESC{'n16'} = 'method_is_post';
sub n16 {
    my ($resource, $request, $response, $metadata) = @_;
    $request->method eq 'POST' ? \&n11 : \&o16
}

$STATE_DESC{'014'} = 'in_conflict';
sub o14 {
    my ($resource, $request, $response, $metadata) = @_;
    return \409 if $resource->is_conflict;
    #...

}


# $STATE_DESC{''} = '';
# sub x {
#     my ($resource, $request, $response, $metadata) = @_;
#     #...
#
# }
#

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
