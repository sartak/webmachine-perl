#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use Plack::Request;
use Plack::Response;

BEGIN {
    use_ok('Web::Machine::FSM');
}

{
    package My::Resource;
    use Moose;

    with 'Web::Machine::Resource';

    sub content_types_provided { [[ 'text/html' => 'to_html' ]] }

    sub to_html { '<html><body>Hello World</body></html>' }
}

my $fsm = Web::Machine::FSM->new;

my @envs = (
    {
        REQUEST_METHOD    => 'GET',
        SERVER_PROTOCOL   => 'HTTP/1.1',
        SERVER_NAME       => 'example.com',
        SCRIPT_NAME       => '/foo',
    },
    {
        SCRIPT_NAME          => '',
        SERVER_NAME          => '127.0.0.1',
        HTTP_ACCEPT_ENCODING => 'gzip, deflate',
        PATH_INFO            => '/',
        HTTP_ACCEPT          => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        REQUEST_METHOD       => 'GET',
        HTTP_USER_AGENT      => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/534.53.11 (KHTML, like Gecko) Version/5.1.3 Safari/534.53.10',
        QUERY_STRING         => '',
        SERVER_PORT          => 5000,
        HTTP_CACHE_CONTROL   => 'max-age=0',
        HTTP_ACCEPT_LANGUAGE => 'en-us',
        REMOTE_ADDR          => '127.0.0.1',
        SERVER_PROTOCOL      => 'HTTP/1.1',
        REQUEST_URI          => '/',
        REMOTE_HOST          => '127.0.0.1',
        HTTP_HOST            => '0:5000',
    }
);

foreach my $env ( @envs ) {
    my $r = My::Resource->new(
        request  => Plack::Request->new( $env ),
        response => Plack::Response->new
    );
    does_ok($r, 'Web::Machine::Resource');

    is_deeply(
        $fsm->run( $r )->finalize,
        [
            200,
            [
            'Content-Length' => 37,
            'Content-Type'   => 'text/html'
            ],
            [ '<html><body>Hello World</body></html>' ]
        ],
        '... got the response expected'
    );
}

done_testing;