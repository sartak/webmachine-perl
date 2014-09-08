#!perl

use strict;
use warnings;

use Router::Boom;
use Web::Machine;
use Plack::Request;

=pod

This example demonstrates one possible approach to API versioning with
the Accept header.  Each URI is associated with one or more resources.
Each resource declares its API version in its media type string. Each
resource is tried until one is found that accepts the requested media
type.
 
# Returns "package : Foo::V1"
curl -v http://0:5000/foo -H 'Accept: application/json; version=1'
 
# Returns "package : Foo::V2"
curl -v http://0:5000/foo -H 'Accept: application/json; version=2'

# Returns "package : Bar::V1"
curl -v http://0:5000/bar -H 'Accept: application/json; version=1'

# Returns a 406 Not Acceptable response.
curl -v http://0:5000/bar -H 'Accept: application/json; version=2'

=cut

{
    package Foo::V1;
    use parent 'Web::Machine::Resource';
    sub content_types_provided {[
        { 'application/json; version=1' => sub {'package : Foo::V1'} }
    ]}
}

{
    package Foo::V2;
    use parent 'Web::Machine::Resource';
    sub content_types_provided {[
        { 'application/json; version=2' => sub {'package : Foo::V2'} }
    ]}
}

{
    package Bar::V1;
    use parent 'Web::Machine::Resource';
    sub content_types_provided {[
        { 'application/json; version=1' => sub {'package : Bar::V1'} }
    ]}
}

my $app = sub {
    my $env    = shift;
    my $req    = Plack::Request->new($env);
    my $router = Router::Boom->new();

    # Map URIs to a destination.  Router::Boom allows the destination
    # to be any scalar value, so we can supply an arrayref containing
    # a list of Web::Machine::Resource classes.
    $router->add('/foo', ['Foo::V1', 'Foo::V2']);
    $router->add('/bar', ['Bar::V1']);

    # Attempt to match the request URI to a route.  On success, the
    # destination (our list of possible resources) will be returned,
    # along with any captured path parts (of which there will be none
    # in this example).  On failure, a 404 response is returned.
    my ($resources, $matches) = $router->match($req->path_info)
        or return $req->new_response(404)->finalize;

    my $res;

    # A resource will return 406 Not Acceptable if it does not advertise
    # the appropriate media type in its content_types_provided() method.
    # Given a list of resources associated with our URI, try each in turn.
    # The first that does not return a 406 response is used to handle the
    # request.
    for my $resource (@$resources) {
        $res = Web::Machine->new(resource => $resource)->to_app->($env);
        last unless $res->[0] == 406;
    }

    $res;
};
