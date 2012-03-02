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

    sub to_html { '<html><body>Hello World</body></html>' }
}

my $fsm = Web::Machine::FSM->new;

my $r = My::Resource->new(
    request  => Plack::Request->new({
        REQUEST_METHOD    => 'GET',
        SERVER_PROTOCOL   => 'HTTP/1.1',
        SERVER_NAME       => 'example.com',
        SCRIPT_NAME       => '/foo',
    }),
    response => Plack::Response->new
);
does_ok($r, 'Web::Machine::Resource');

use Data::Dumper; warn Dumper $fsm->run( $r )->finalize;

done_testing;