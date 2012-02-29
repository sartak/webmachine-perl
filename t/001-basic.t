#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Plack::Request;
use Plack::Response;

BEGIN {
    use_ok('Web::Machine::FSM');
}

{
    package My::Resource;

    use strict;
    use warnings;

    use Web::Machine::Util;

    use parent 'Web::Machine::Resource';

    sub to_html { '<html><body>Hello World</body></html>' }
}

my $fsm = Web::Machine::FSM->new;

my $r = My::Resource->new(
    request  => Plack::Request->new({
        REQUEST_METHOD    => 'GET',
        SERVER_PROTOCOL   => 'HTTP/1.1',
        SERVER_PORT       => 80,
        SERVER_NAME       => 'example.com',
        SCRIPT_NAME       => '/foo',
        REMOTE_ADDR       => '127.0.0.1',
    }),
    response => Plack::Response->new
);
isa_ok($r, 'Web::Machine::Resource');

use Data::Dumper; warn Dumper $fsm->run( $r )->finalize;

done_testing;