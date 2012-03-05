package Web::Machine::Resource;
use Moose::Role;

has 'request' => (
    is       => 'ro',
    isa      => 'Plack::Request',
    required => 1
);

has 'response' => (
    is       => 'ro',
    isa      => 'Plack::Response',
    required => 1
);

sub resource_exists           { 1 }
sub service_available         { 1 }
sub is_authorized             { 1 }
sub forbidden                 { 0 }
sub allow_missing_post        { 0 }
sub malformed_request         { 0 }
sub uri_too_long              { 0 }
sub known_content_type        { 1 }
sub valid_content_headers     { 1 }
sub valid_entity_length       { 1 }
sub options                   { +{} }
sub allowed_methods           { [qw[ GET HEAD ]] }
sub known_methods             { [qw[ GET HEAD POST PUT DELETE TRACE CONNECT OPTIONS ]]}
sub delete_resource           { 0 }
sub delete_completed          { 1 }
sub post_is_create            { 0 }
sub create_path               { undef }
sub base_uri                  { undef }
sub process_post              { 0 }
sub content_types_provided    { [] }
sub content_types_accepted    { [] }
sub charsets_provided         { undef }
sub languages_provided        { [] }
sub encodings_provided        { { 'identity' => sub { $_[1] } } }
sub variances                 { [] }
sub is_conflict               { 0 }
sub multiple_choices          { 0 }
sub previously_existed        { 0 }
sub moved_permanently         { 0 }
sub moved_temporarily         { 0 }
sub last_modified             { undef }
sub expires                   { undef }
sub generate_etag             { undef }
sub finish_request            {}

no Moose::Role; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Resource;

=head1 DESCRIPTION

=over 4

=item C<resource_exists>

Does the resource exist?

Returning a false value will result in a '404 Not Found'
response.

Defaults to true.

=item C<service_available>

Is the resource available?

Returning a false value will result in a '503 Service Not
Available' response.

Defaults to true.

If the resource is only temporarily not available, add a
'Retry-After' response header in the body of the method.

=item C<is_authorized ( ?$authorization_header )>

Is the client or request authorized?

Parameter C<$authorization_header> is the contents of the
'Authorization' header sent by the client, if present.

Returning anything other than true will result in a
'401 Unauthorized' response. If a string is returned, it
will be used as the value in the 'WWW-Authenticate'
response header, which can also be set manually.

Defaults to true.

=item C<forbidden>

Is the request or client forbidden?

Returning a true value will result in a '403 Forbidden' response.

Defaults to false.

=item C<allow_missing_post>

If the resource accepts POST requests to nonexistent resources,
then this should return true.

Defaults to false.

=item C<malformed_request>

If the request is malformed, this should return true, which will
result in a '400 Malformed Request' response.

Defaults to false.

=item C<uri_too_long( $uri )>

If the URI is too long to be processed, this should return true,
which will result in a '414 Request URI Too Long' response.

Defaults to false.

=item C<known_content_type( $content_type )>

If the 'Content-Type' on PUT or POST is unknown, this should
return false, which will result in a '415 Unsupported Media
Type' response.

Defaults to true.

=item C<valid_content_headers( $content_headers )>

Parameter C<$content_header> is a HASH ref of the Request
headers that begin with prefix 'Content-'.

If the request includes any invalid Content-* headers, this
should return false, which will result in a '501 Not
Implemented' response.

Defaults to false.

=item C<valid_entity_length( $length )>

Parameter C<$length> is a number indicating the size of the
request body.

If the entity length on PUT or POST is invalid, this should
return false, which will result in a '413 Request Entity Too
Large' response.

Defaults to true.

=item C<options>

If the OPTIONS method is supported and is used, this method
should return a HASH ref of headers that should appear in the
response.

Defaults to {}.

=item C<allowed_methods>

HTTP methods that are allowed on this resource. This must return
an ARRAY ref of strings in all capitals.

Defaults to C<['GET','HEAD']>.

=items C<known_methods>

HTTP methods that are known to the resource. Like C<allowed_methods>,
this must return an ARRAY ref of strings in all capitals. One could
override this callback to allow additional methods, e.g. WebDAV.

Default includes all standard HTTP methods, C<['GET', 'HEAD', 'POST',
'PUT', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS']>.

=item C<delete_resource>

This method is called when a DELETE request should be enacted,
and should return true if the deletion succeeded.

Defaults to false.

=item C<delete_completed>

This method is called after a successful call to C<delete_resource>
and should return false if the deletion was accepted but cannot yet
be guaranteed to have finished.

Defaults to true.

=item C<post_is_create>

If POST requests should be treated as a request to put content
into a (potentially new) resource as opposed to a generic
submission for processing, then this method should return
true. If it does return true, then C<create_path> will be called
and the rest of the request will be treated much like a PUT to
the path returned by that call.

Default is false.

=item C<create_path>

This will be called on a POST request if post_is_create? returns
true. The path returned should be a valid URI part following the
dispatcher prefix.

=item C<base_uri>

This will be called after C<create_path> but before setting the
Location response header, and is used to determine the root
URI of the new resource.

Default is nil, which uses the URI of the request as the base.

=item C<process_post>

If post_is_create? returns false, then this will be called to
process any POST request. If it succeeds, it should return true.

=item C<content_types_provided>

This should return an ARRAY of pairs where each pair is of the
form [ C<$mediatype>, C<&handler> ] where C<$mediatype> is a
string of Content-Type format and C<&handler> is a CODE ref of
a method which can provide a resource representation in that
media type.

For example, if a client request includes an 'Accept' header with
a value that does not appear as a first element in any of the return
pairs, then a '406 Not Acceptable' will be sent.

Default is an empty ARRAY ref.

=item C<content_types_accepted>

Similarly to content_types_provided, this should return an array
of mediatype/handler pairs, except that it is for incoming
resource representations -- for example, PUT requests. Handler
functions usually want to use C<< $request->body >> to access the
incoming entity.

=item C<charsets_provided>

If this is anything other than undef, it must be an ARRAY of pairs
where each pair is of the form Charset, Converter where Charset
is a string naming a charset and Converter is an arity-1 method
in the resource which will be called on the produced body in a
GET and ensure that it is in Charset.

Default is undef.

=item C<languages_provided>

This should return a list of language tags provided by the
resource. Default is the empty Array, in which the content is
in no specific language.

=item C<encodings_provided>

This should return a hash of encodings mapped to encoding
methods for Content-Encodings your resource wants to
provide. The encoding will be applied to the response body
automatically by Webmachine.

Default includes only the 'identity' encoding.

=item C<variances>

If this method is implemented, it should return a list of
strings with header names that should be included in a given
response's Vary header. The standard conneg headers (Accept,
Accept-Encoding, Accept-Charset, Accept-Language) do not need to
be specified here as Webmachine will add the correct elements of
those automatically depending on resource behavior.

Default is [].

=item C<is_conflict>

If this returns true, the client will receive a '409 Conflict'
response. This is only called for PUT requests.

Default is false.

=item C<multiple_choices>

If this returns true, then it is assumed that multiple
representations of the response are possible and a single one
cannot be automatically chosen, so a 300 Multiple Choices will
be sent instead of a 200.

Default is false.

=item C<previously_existed>

If this resource is known to have existed previously, this
method should return true.

Default is false.

=item C<moved_permanently>

If this resource has moved to a new location permanently, this
method should return the new location as a String or URI.

Default is to return false.

=item C<moved_temporarily>

If this resource has moved to a new location temporarily, this
method should return the new location as a String or URI.

Default is to return false.

=item C<last_modified>

This method should return the last modified date/time of the
resource which will be added as the Last-Modified header in the
response and used in negotiating conditional requests.

Default is undef.

=item C<expires>

If the resource expires, this method should return the date/time
it expires.

Default is nil.

=item C<generate_etag>

If this returns a value, it will be used as the value of the
ETag header and for comparison in conditional requests.

Default is undef.

=item C<finish_request>

This method is called just before the final response is
constructed and sent. The return value is ignored, so any effect
of this method must be by modifying the response.

