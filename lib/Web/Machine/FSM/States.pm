package Web::Machine::FSM::States;
# ABSTRACT: The States for Web Machine

use strict;
use warnings;

use B ();
use Hash::MultiValue;

use Carp qw[ confess ];

use Web::Machine::Util qw[
    first
    pair_key
    pair_value
    create_header
];
use Web::Machine::Util::BodyEncoding qw[
    encode_body_if_set
    encode_body
];
use Web::Machine::Util::ContentNegotiation qw[
    choose_media_type
    match_acceptable_media_type
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
        get_state_desc
    ]]
};

my %STATE_DESC;

# my exports ...

sub start_state    { \&b13 }
sub is_status_code { ref $_[0] eq 'SCALAR' }
sub is_new_state   { ref $_[0] eq 'CODE'   }
sub get_state_name { B::svref_2object( shift )->GV->NAME }
sub get_state_desc { $STATE_DESC{ ref $_[0] ? get_state_name( shift ) : shift } }

# some utilities ...

sub _unquote_header {
    my $value = shift;
    if ( $value =~ /^"(.*)"$/ ) {
        return $1;
    }
    return $value;
}

sub _ensure_quoted_header {
    my $value = shift;
    return $value if $value =~ /^"(.*)"$/;
    return '"' . $value . '"';
}

sub _get_acceptable_content_type_handler {
    my ($resource, $request) = @_;
    my $acceptable = match_acceptable_media_type(
        ($request->header('Content-Type') || 'application/octet-stream'),
        $resource->content_types_accepted
    );
    return \415 unless $acceptable;
    return pair_value( $acceptable );
}

sub _add_caching_headers {
    my ($resource, $response) = @_;
    if ( my $etag = $resource->generate_etag ) {
        $response->header( 'Etag' => _ensure_quoted_header( $etag ) );
    }
    if ( my $expires = $resource->expires ) {
        $response->header( 'Expires' => $expires );
    }
    if ( my $modified = $resource->last_modified ) {
        $response->header( 'Last-Modified' => $modified );
    }
}

sub _handle_304 {
    my ($resource, $response) = @_;
    $response->headers->remove_header('Content-Type');
    $response->headers->remove_header('Content-Encoding');
    $response->headers->remove_header('Content-Language');
    _add_caching_headers($resource, $response);
    return \304;
}

sub _is_redirect {
    my ($response) = @_;
    # NOTE:
    # this makes a guess that the user has
    # told the Plack::Response that they
    # want to redirect. We do this based
    # on the fact that the ->redirect method
    # will set the status, while in almost all
    # other cases the status of the response
    # will not be set yet.
    # - SL
    return 1 if $response->status;
    return;
}

sub _metadata {
    my ($request) = @_;
    return $request->env->{'web.machine.context'};
}

## States

$STATE_DESC{'b13'} = 'service_available';
sub b13 {
    my ($resource, $request, $response) = @_;
    $resource->service_available ? \&b12 : \503;
}

$STATE_DESC{'b12'} = 'known_method';
sub b12 {
    my ($resource, $request, $response) = @_;
    my $method = $request->method;
    (grep { $method eq $_ } @{ $resource->known_methods }) ? \&b11 : \501;
}

$STATE_DESC{'b11'} = 'uri_too_long';
sub b11 {
    my ($resource, $request, $response) = @_;
    $resource->uri_too_long( $request->uri ) ? \414 : \&b10;
}

$STATE_DESC{'b10'} = 'method_allowed';
sub b10 {
    my ($resource, $request, $response) = @_;
    my $method = $request->method;
    return \&b9 if grep { $method eq $_ } @{ $resource->allowed_methods };
    $response->header('Allow' => join ", " => @{ $resource->allowed_methods } );
    return \405;
}

$STATE_DESC{'b9'} = 'malformed_request';
sub b9 {
    my ($resource, $request, $response) = @_;
    $resource->malformed_request ? \400 : \&b8;
}

$STATE_DESC{'b8'} = 'is_authorized';
sub b8 {
    my ($resource, $request, $response) = @_;
    my $result = $resource->is_authorized( $request->header('Authorization') );
    # if we get back a status, then use it
    if ( is_status_code( $result ) ) {
        return $result;
    }
    # if we just get back true, then
    # move onto the next state
    elsif ( defined $result && "$result" eq "1" ) {
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
    my ($resource, $request, $response) = @_;
    $resource->forbidden ? \403 : \&b6;
}

$STATE_DESC{'b6'} = 'content_headers_okay';
sub b6 {
    my ($resource, $request, $response) = @_;

    # FIX-ME
    # there is a better way to do this,
    # also, HTTP::Headers will usually
    # group things into arrays, so we
    # can either avoid or better take
    # advantage of Hash::MultiValue.
    # But we are almost certainly not
    # handling that case properly maybe.
    my $content_headers = Hash::MultiValue->new;
    $request->headers->scan(sub {
        my ($name, $value) = @_;
        $content_headers->add( $name, $value ) if (lc $name) =~ /^content-/;
    });

    $resource->valid_content_headers( $content_headers ) ? \&b5 : \501;
}

$STATE_DESC{'b5'} = 'known_content_type';
sub b5 {
    my ($resource, $request, $response) = @_;
    $resource->known_content_type( $request->content_type ) ? \&b4 : \415;
}

$STATE_DESC{'b4'} = 'request_entity_too_large';
sub b4 {
    my ($resource, $request, $response) = @_;
    $resource->valid_entity_length( $request->content_length ) ? \&b3 : \413;
}

$STATE_DESC{'b3'} = 'method_is_options';
sub b3 {
    my ($resource, $request, $response) = @_;
    if ( $request->method eq 'OPTIONS' ) {
        $response->headers( $resource->options );
        return \200;
    }
    return \&c3
}

$STATE_DESC{'c3'} = 'accept_header_exists';
sub c3 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    if ( !$request->header('Accept') ) {
        $metadata->{'Content-Type'} = create_header( MediaType => (
            pair_key( $resource->content_types_provided->[0] )
        ));
        return \&d4
    }
    return \&c4;
}

$STATE_DESC{'c4'} = 'acceptable_media_type_available';
sub c4 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);

    my @types = map { pair_key( $_ ) } @{ $resource->content_types_provided };

    if ( my $chosen_type = choose_media_type( \@types, $request->header('Accept') ) ) {
        $metadata->{'Content-Type'} = $chosen_type;
        return \&d4;
    }

    return \406;
}

$STATE_DESC{'d4'} = 'accept_language_header_exists';
sub d4 {
    my ($resource, $request, $response) = @_;
    (not $request->header('Accept-Language')) ? \&e5 : \&d5;
}


$STATE_DESC{'d5'} = 'accept_language_choice_available';
sub d5 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);

    if ( my $language = choose_language( $resource->languages_provided, $request->header('Accept-Language') ) ) {
        $metadata->{'Language'} = $language;
        # handle the short circuit here ...
        $response->header( 'Content-Language' => $language ) if "$language" ne "1";
        return \&e5;
    }

    return \406;
}

$STATE_DESC{'e5'} = 'accept_charset_exists';
sub e5 {
    my ($resource, $request, $response) = @_;
    (not $request->header('Accept-Charset')) ? \&f6 : \&e6;
}

$STATE_DESC{'e6'} = 'accept_charset_choice_available';
sub e6 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);

    if ( my $charset = choose_charset( $resource->charsets_provided, $request->header('Accept-Charset') ) ) {
        # handle the short circuit here ...
        $metadata->{'Charset'} = $charset if "$charset" ne "1";
        return \&f6;
    }

    return \406;
}

$STATE_DESC{'f6'} = 'accept_encoding_exists';
# (also, set content-type header here, now that charset is chosen)
sub f6 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    if ( my $charset = $metadata->{'Charset'} ) {
        # Add the charset to the content type now ...
        $metadata->{'Content-Type'}->add_param( 'charset' => $charset );
    }
    # put the content type in the header now ...
    $response->header( 'Content-Type' => $metadata->{'Content-Type'}->as_string );

    if ( $request->header('Accept-Encoding') ) {
        return \&f7
    }
    else {
        if ( my $encoding = choose_encoding( $resource->encodings_provided, "identity;q=1.0,*;q=0.5" ) ) {
            $response->header( 'Content-Encoding' => $encoding ) unless $encoding eq 'identity';
            $metadata->{'Content-Encoding'} = $encoding;
            return \&g7;
        }
        else {
            return \406;
        }
    }
}

$STATE_DESC{'f7'} = 'accept_encoding_choice_available';
sub f7 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);

    if ( my $encoding = choose_encoding( $resource->encodings_provided, $request->header('Accept-Encoding') ) ) {
        $response->header( 'Content-Encoding' => $encoding ) unless $encoding eq 'identity';
        $metadata->{'Content-Encoding'} = $encoding;
        return \&g7;
    }

    return \406;
}

$STATE_DESC{'g7'} = 'resource_exists';
sub g7 {
    my ($resource, $request, $response) = @_;

    # NOTE:
    # set Vary header here since we are
    # done with content negotiation
    # - SL
    my @variances = @{ $resource->variances };

    push @variances => 'Accept'          if scalar @{ $resource->content_types_provided } > 1;
    push @variances => 'Accept-Encoding' if scalar keys %{ $resource->encodings_provided } > 1;
    push @variances => 'Accept-Charset'  if defined $resource->charsets_provided && scalar @{ $resource->charsets_provided } > 1;
    push @variances => 'Accept-Language' if scalar @{ $resource->languages_provided } > 1;

    $response->header( 'Vary' => join ', ' => @variances ) if @variances;

    $resource->resource_exists ? \&g8 : \&h7;
}

$STATE_DESC{'g8'} = 'if_match_exists';
sub g8 {
    my ($resource, $request, $response) = @_;
    $request->header('If-Match') ? \&g9 : \&h10;
}

$STATE_DESC{'g9'} = 'if_match_is_wildcard';
sub g9 {
    my ($resource, $request, $response) = @_;
    _unquote_header( $request->header('If-Match') ) eq "*" ? \&h10 : \&g11;
}

$STATE_DESC{'g11'} = 'etag_in_if_match_list';
sub g11 {
    my ($resource, $request, $response) = @_;
    my @etags = map { _unquote_header( $_ ) } split /\s*\,\s*/ => $request->header('If-Match');
    my $etag  = $resource->generate_etag;
    (grep { $etag eq $_ } @etags) ? \&h10 : \412;
}

$STATE_DESC{'h7'} = 'if_match_exists_and_if_match_is_wildcard';
sub h7 {
    my ($resource, $request, $response) = @_;
    ($request->header('If-Match') && _unquote_header( $request->header('If-Match') ) eq "*") ? \412 : \&i7;
}

$STATE_DESC{'h10'} = 'if_unmodified_since_exists';
sub h10 {
    my ($resource, $request, $response) = @_;
    $request->header('If-Unmodified-Since') ? \&h11 : \&i12;
}

$STATE_DESC{'h11'} = 'if_unmodified_since_is_valid_date';
sub h11 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    if ( my $date = $request->header('If-Unmodified-Since') ) {
        $metadata->{'If-Unmodified-Since'} = $date;
        return \&h12;
    }
    return \&i12;
}

$STATE_DESC{'h12'} = 'last_modified_is_greater_than_if_unmodified_since';
sub h12 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    defined $resource->last_modified
        &&
    ($resource->last_modified->epoch > $metadata->{'If-Unmodified-Since'}->epoch)
        ? \412 : \&i12;
}

$STATE_DESC{'i4'} = 'moved_permanently';
sub i4 {
    my ($resource, $request, $response) = @_;
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
    my ($resource, $request, $response) = @_;
    $request->method eq 'PUT' ? \&i4 : \&k7
}

$STATE_DESC{'i12'} = 'if_none_match_exists';
sub i12 {
    my ($resource, $request, $response) = @_;
    $request->header('If-None-Match') ? \&i13 : \&l13
}

$STATE_DESC{'i13'} = 'if_none_match_is_wildcard';
sub i13 {
    my ($resource, $request, $response) = @_;
    $request->header('If-None-Match') eq "*" ? \&j18 : \&k13
}

$STATE_DESC{'j18'} = 'method_is_get_or_head';
sub j18 {
    my ($resource, $request, $response) = @_;
    $request->method eq 'GET' || $request->method eq 'HEAD'
        ? _handle_304( $resource, $response )
        : \412
}

$STATE_DESC{'k5'} = 'moved_permanently';
sub k5 {
    my ($resource, $request, $response) = @_;
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
    my ($resource, $request, $response) = @_;
    $resource->previously_existed ? \&k5 : \&l7;
}

$STATE_DESC{'k13'} = 'etag_in_if_none_match';
sub k13 {
    my ($resource, $request, $response) = @_;
    my @etags = map { _unquote_header( $_ ) } split /\s*\,\s*/ => $request->header('If-None-Match');
    my $etag  = $resource->generate_etag;
    (grep { $etag eq $_ } @etags) ? \&j18 : \&l13;
}

$STATE_DESC{'l5'} = 'moved_temporarily';
sub l5 {
    my ($resource, $request, $response) = @_;
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
    my ($resource, $request, $response) = @_;
    $request->method eq 'POST' ? \&m7 : \404
}

$STATE_DESC{'l13'} = 'if_modified_since_exists';
sub l13 {
    my ($resource, $request, $response) = @_;
    $request->header('If-Modified-Since') ? \&l14 : \&m16
}

$STATE_DESC{'l14'} = 'if_modified_since_is_valid_date';
sub l14 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    if ( my $date = $request->header('If-Modified-Since') ) {
        $metadata->{'If-Modified-Since'} = $date;
        return \&l15;
    }
    return \&m16;
}

$STATE_DESC{'l15'} = 'if_modified_since_greater_than_now';
sub l15 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    ($metadata->{'If-Modified-Since'}->epoch > (scalar time)) ? \&m16 : \&l17;
}

$STATE_DESC{'l17'} = 'last_modified_is_greater_than_if_modified_since';
sub l17 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    defined $resource->last_modified
        &&
    ($resource->last_modified->epoch > $metadata->{'If-Modified-Since'}->epoch)
        ? \&m16 : _handle_304( $resource, $response );
}

$STATE_DESC{'m5'} = 'method_is_post';
sub m5 {
    my ($resource, $request, $response) = @_;
    $request->method eq 'POST' ? \&n5 : \410
}

$STATE_DESC{'m7'} = 'allow_post_to_missing_resource';
sub m7 {
    my ($resource, $request, $response) = @_;
    $resource->allow_missing_post ? \&n11 : \404
}

$STATE_DESC{'m16'} = 'method_is_delete';
sub m16 {
    my ($resource, $request, $response) = @_;
    $request->method eq 'DELETE' ? \&m20 : \&n16
}

$STATE_DESC{'m20'} = 'delete_enacted_immediately';
sub m20 {
    my ($resource, $request, $response) = @_;
    $resource->delete_resource ? \&m20b : \500
}

$STATE_DESC{'m20b'} = 'did_delete_complete';
sub m20b {
    my ($resource, $request, $response) = @_;
    $resource->delete_completed ? \&o20 : \202
}

$STATE_DESC{'n5'} = 'allow_post_to_missing_resource';
sub n5 {
    my ($resource, $request, $response) = @_;
    $resource->allow_missing_post ? \&n11 : \410
}

$STATE_DESC{'n11'} = 'redirect';
sub n11 {
    my ($resource, $request, $response) = @_;
    if ( $resource->post_is_create ) {
        my $uri = $resource->create_path;
        confess "Create Path Nil" unless $uri;
        my $base_uri = $resource->base_uri || $request->base;

        # do a little cleanup
        $base_uri =~ s!/$!! if $uri =~ m!^/!;
        $base_uri .= '/'    if $uri !~ m!^/! && $base_uri !~ m!/$!;
        my $new_uri = URI->new( $base_uri . $uri )->canonical;
        # NOTE:
        # the ruby and JS versions will set the path_info
        # for the request object here, but since our requests
        # are immutable, we don't allow that. I don't see
        # where this ends up being useful so I am going to
        # skip it and not bother.
        # - SL
        $response->header( 'Location' => $new_uri->path );

        my $handler = _get_acceptable_content_type_handler( $resource, $request );
        return $handler if is_status_code( $handler );

        my $result  = $resource->$handler();

        return $result if is_status_code( $result );
    }
    else {
        my $result = $resource->process_post;
        if ( $result ) {
            return $result if is_status_code( $result );
            encode_body_if_set( $resource, $response );
        }
        else {
            confess "Process Post Invalid";
        }
    }

    if ( _is_redirect( $response ) ) {
        if ( $response->location ) {
            return \303;
        }
        else {
            confess "Bad Redirect"
        }
    }

    return \&p11;
}

$STATE_DESC{'n16'} = 'method_is_post';
sub n16 {
    my ($resource, $request, $response) = @_;
    $request->method eq 'POST' ? \&n11 : \&o16
}

$STATE_DESC{'o14'} = 'in_conflict';
sub o14 {
    my ($resource, $request, $response) = @_;
    return \409 if $resource->is_conflict;

    my $handler = _get_acceptable_content_type_handler( $resource, $request );
    return $handler if is_status_code( $handler );

    my $result  = $resource->$handler();

    return $result if is_status_code( $result );
    return \&p11;
}

$STATE_DESC{'o16'} = 'method_is_put';
sub o16 {
    my ($resource, $request, $response) = @_;
    $request->method eq 'PUT' ? \&o14 : \&o18;
}

$STATE_DESC{'o18'} = 'multiple_representations';
sub o18 {
    my ($resource, $request, $response) = @_;
    my $metadata = _metadata($request);
    if ( $request->method eq 'GET' || $request->method eq 'HEAD' ) {
        _add_caching_headers( $resource, $response );

        my $content_type = $metadata->{'Content-Type'};
        my $match        = first {
            my $ct = create_header( MediaType => pair_key( $_ ) );
            $content_type->match( $ct )
        } @{ $resource->content_types_provided };

        my $handler = pair_value( $match );
        my $result  = $resource->$handler();

        return $result if is_status_code( $result );

        unless($request->method eq 'HEAD') {
            $response->body( $result );
            encode_body( $resource, $response );
        }
        return \&o18b;
    }
    else {
        return \&o18b;
    }

}

$STATE_DESC{'o18b'} = 'multiple_choices';
sub o18b {
    my ($resource, $request, $response) = @_;
    $resource->multiple_choices ? \300 : \200;
}

$STATE_DESC{'o20'} = 'response_body_includes_entity';
sub o20 {
    my ($resource, $request, $response) = @_;
    $response->body ? \&o18 : \204;
}

$STATE_DESC{'p3'} = 'in_conflict';
sub p3 {
    my ($resource, $request, $response) = @_;
    return \409 if $resource->is_conflict;

    my $handler = _get_acceptable_content_type_handler( $resource, $request );
    return $handler if is_status_code( $handler );

    my $result  = $resource->$handler();

    return $result if is_status_code( $result );
    return \&p11;
}

$STATE_DESC{'p11'} = 'new_resource';
sub p11 {
    my ($resource, $request, $response) = @_;
    (not $response->header('Location')) ? \&o20 : \201
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::FSM::States;

=head1 DESCRIPTION

For now I am going to say that there is nothing to see here and that
if you really want to know what is going on, you should read the
source (and consult the diagram linked to below). Eventualy I might
try and document this, but for now the task is simply too daunting.

=head1 SEE ALSO

=over 4

=item L<Web Machine state diagram|http://wiki.basho.com/Webmachine-Diagram.html>

=back



