#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Plack::Request;
use Plack::Response;

BEGIN {
    use_ok('Web::Machine');
}

{
    package My::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html { '<html><body>Hello World</body></html>' }
}

my $app = Web::Machine->new(
    resource => 'My::Resource',
    fsm_args => { tracing => 1 }
)->to_app;

my @tests = (
    {
        trace => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,l13,m16,n16,o16,o18,o18b',
        env   => {
            REQUEST_METHOD    => 'GET',
            SERVER_PROTOCOL   => 'HTTP/1.1',
            SERVER_NAME       => 'example.com',
            SCRIPT_NAME       => '/foo',
        }
    },
    {
        trace => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,f6,f7,g7,g8,h10,i12,l13,m16,n16,o16,o18,o18b',
        env   => {
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
    }
);

foreach my $test ( @tests ) {

    my $resp = $app->( $test->{'env'} );
    is_deeply(
        $resp,
        [
            200,
            [
            'Content-Length'      => 37,
            'Content-Type'        => 'text/html',
            'X-Web-Machine-Trace' => $test->{'trace'}
            ],
            [ '<html><body>Hello World</body></html>' ]
        ],
        '... got the response expected'
    );
}

done_testing;