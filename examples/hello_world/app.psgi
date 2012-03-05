#!perl

use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Web::Machine::FSM;

{
    package HelloWorld::Resource;
    use Moose;

    with 'Web::Machine::Resource';

    sub content_types_provided { [[ 'text/html' => 'to_html' ]] }

    sub to_html {
        join "" =>
        '<html>',
            '<head>',
                '<title>Hello World Resource</title>',
            '</head>',
            '<body>',
                '<h1>Hello World</h1>',
            '</body>',
        '</html>'
    }
}

sub {
    Web::Machine::FSM->new->run(
        HelloWorld::Resource->new(
            request  => Plack::Request->new( shift ),
            response => Plack::Response->new,
        )
    )->finalize;
};
