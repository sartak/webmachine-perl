package Web::Machine::Resource;
# ABSTRACT: A base resource class

use strict;
use warnings;

use Carp         qw[ confess ];
use Scalar::Util qw[ blessed ];

sub new {
    my ($class, %args) = @_;

    (exists $args{'request'} && blessed $args{'request'} && $args{'request'}->isa('Plack::Request'))
        || confess "You must supply a request and it must be a Plack::Request";

    (exists $args{'response'} && blessed $args{'response'} && $args{'response'}->isa('Plack::Response'))
        || confess "You must supply a response and it must be a Plack::Response";

    my $self = bless {
        request  => $args{'request'},
        response => $args{'response'},
    } => $class;

    $self->init( \%args );
    $self;
}

sub init {}

sub request  { (shift)->{'request'}  }
sub response { (shift)->{'response'} }

# NOTE:
# this is where we deviate from
# the Erlang/Ruby versions
# - SL
sub create_path_after_handler { 0 }

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
sub charsets_provided         { [] }
sub default_charset           {}
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

1;

__END__

=head1 SYNOPSIS

  package HelloWorld::Resource;
  use strict;
  use warnings;

  use parent 'Web::Machine::Resource';

  sub content_types_provided { [{ 'text/html' => 'to_html' }] }

  sub to_html {
      q{<html>
          <head>
              <title>Hello World Resource</title>
          </head>
          <body>
              <h1>Hello World</h1>
          </body>
       </html>}
  }

=head1 DESCRIPTION

This is the core representation of the web resource in
L<Web::Machine>. It is this object which is interrogated
through the state machine. It is important not to think
of this as an instance of a single object, but as a web
representation of a resource, there is a big difference.

For now I am keeping the docs short, but much more needs
to be written here. Below you will find a description of
each method this object provides and what is expected of
it. These docs were lovingly stolen from the ruby port
of webmachine.

=head1 METHODS

=over 4

=item C<init( \%args )>

This method is called right after the object is blessed
and it is passed reference to the original C<%args> that
were given to the constructor.

The default method is a no-op, so there is no need to call
the SUPER method, however it is still recommended to
ensure proper initialization.

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

The C<$content_type> provided should be an instance of
L<HTTP::Headers::ActionPack::MediaType>.

Defaults to true.

=item C<valid_content_headers( $content_headers )>

Parameter C<$content_header> is a HASH ref of the Request
headers that begin with prefix 'Content-'. It will contain
instances of L<HTTP::Headers::ActionPack::MediaType>,
L<HTTP::Headers::ActionPack::MediaTypeList> and
L<HTTP::Headers::ActionPack::PriorityList> based on the
headers included. See L<HTTP::Headers::ActionPack> for
details of the mappings.

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

=item C<known_methods>

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

=item C<create_path_after_handler>

This changes the behavior of C<create_path> so that it will fire
I<after> the content handler has processed the request body. This
allows the creation of paths that are more tightly tied to the
newly created entity.

Default is false.

=item C<base_uri>

This will be called after C<create_path> but before setting the
Location response header, and is used to determine the root
URI of the new resource.

Default is nil, which uses the URI of the request as the base.

=item C<process_post>

If post_is_create? returns false, then this will be called to
process any POST request. If it succeeds, it should return true.

=item C<content_types_provided>

This should return an ARRAY of HASH ref pairs where the key is
name of the media type and the value is a CODE ref of a method
which can provide a resource representation in that media type.

For example, if a client request includes an 'Accept' header with
a value that does not appear as a first element in any of the return
pairs, then a '406 Not Acceptable' will be sent.

Default is an empty ARRAY ref.

=item C<content_types_accepted>

Similarly to content_types_provided, this should return an ARRAY
of mediatype/handler pairs, except that it is for incoming
resource representations -- for example, PUT requests. Handler
functions usually want to use C<< $request->body >> to access the
incoming entity.

=item C<charsets_provided>

This specifies the charsets that your resource support. Returning a value from
this method enable content negotiation based on the client's Accept-Charset
header.

The return value from this method must be an ARRAY ref. Each member of that
array can be either a string or a HASH ref pair value. If the member is a
string, it must be a valid character set name for the L<Encode>
module. Web::Machine will call L<encode()> on the body using this character
set if you set a body.

  sub charsets_provided {
      return [ qw( UTF-8 ISO-8859-1 shiftjis ) ];
  }

If you return a HASHREF pair, the key must be a character set name and the
value must be a CODE ref. This CODE ref will be called I<as a method> on the
resource object. It will receive a single parameter, a string to be
encoded. It is expected to return a scalar containing B<bytes>, not
characters. This will be used to encode the body you provide.

  sub charsets_provided {
      return [
          {
              'UTF-8' => sub {
                  my $self   = shift;
                  my $string = shift;
                  return make_some_bytes($string),;
              },
          },
          {
              'ISO-8859-1' => sub {
                  my $self   = shift;
                  my $string = shift;
                  return strip_non_ascii($string),;
              },
          },
      ];
  }

The character set name will be appended to the Content-Type header returned
the client.

If a client specifies two the same preference for two or more character sets
that your resource provides, then Web::Machine chooses the first character set
in the returned ARRAY ref.

B<CAVEAT:> Note that currently C<Web::Machine> does not support the use of
encodings when the body is returned as a CODE ref. This is a bug to be
remedied in the future.

Default is an empty list.

=item C<default_charset>

If the client does not provide an Accept-Charset header, this sub is called to
provide a default charset. The return value must be either a string or a
hashref consisting of a single pair, where the key is a character set name and
the value is a subroutine.

This works just like the C<charsets_provided()> method, except that you can
only return a single value.

=item C<languages_provided>

This should return a list of language tags provided by the
resource. Default is the empty Array, in which the content is
in no specific language.

=item C<encodings_provided>

This should return a HASH of encodings mapped to encoding
methods for Content-Encodings your resource wants to
provide. The encoding will be applied to the response body
automatically by Webmachine.

B<CAVEAT:> Note that currently C<Web::Machine> does not support the use of
encodings when the body is returned as a CODE ref. This is a bug to be
remedied in the future.

Default includes only the 'identity' encoding.

=item C<variances>

If this method is implemented, it should return a list of
strings with header names that should be included in a given
response's Vary header. The standard content negotiation headers (Accept,
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
response and used in negotiating conditional requests. This
should be in the form of an instance of
L<HTTP::Headers::ActionPack::DateHeader>.

Default is undef.

=item C<expires>

If the resource expires, this method should return the date/time
it expires. This should be in the form of an instance of
L<HTTP::Headers::ActionPack::DateHeader>.

Default is nil.

=item C<generate_etag>

If this returns a value, it will be used as the value of the
ETag header and for comparison in conditional requests.

Default is undef.

=item C<finish_request( $metadata )>

This method is called just before the final response is
constructed and sent. It is passed the collected C<$metadata>
from the FSM, which may or may not have information in it.

The return value is ignored, so any effect of this method
must be by modifying the response.

=back
