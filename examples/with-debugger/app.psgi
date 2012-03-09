#!perl

use strict;
use warnings;

use Plack::Builder;
use Plack::App::Directory;

use Plack::Request;
use Plack::Response;

use Web::Machine::FSM;

{
    package HelloWorld::Resource;
    use Moose;

    with 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

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

builder {
    mount "/debugger" => Plack::App::Directory->new( root => './root/static/' );
    mount "/trace"    => Plack::App::Directory->new( root => './examples/with-debugger/trace' );
    mount "/" => sub {
        Web::Machine::FSM->new(
            trace_file => './examples/with-debugger/trace/trace.js'
        )->run(
            HelloWorld::Resource->new(
                request  => Plack::Request->new( shift ),
                response => Plack::Response->new,
            )
        )->finalize;
    }
};

