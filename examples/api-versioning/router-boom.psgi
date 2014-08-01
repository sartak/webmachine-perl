#!perl

use strict;
use warnings;

use Router::Boom;
use Web::Machine;
use Plack::Request;

=pod
 
curl -v http://0:5000/foo -H 'Accept: application/json; version=1'
 
curl -v http://0:5000/foo -H 'Accept: application/json; version=2'

curl -v http://0:5000/bar -H 'Accept: application/json; version=1'

# 406 Not Acceptable
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

    $router->add('/foo', ['Foo::V1', 'Foo::V2']);
    $router->add('/bar', ['Bar::V1']);

    my ($resources, $matches) = $router->match($req->path_info)
        or return $req->new_response(404)->finalize;

    my $res;

    for my $resource (@$resources) {
        $res = Web::Machine->new(resource => $resource)->to_app->($env);
        last unless $res->[0] == 406;
    }

    $res;
};
