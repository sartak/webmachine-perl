#!/usr/bin/perl

use strict;
use warnings;

use lib 't/010-resources/';

use Test::More;
use Test::FailWarnings;

use Plack::Request;
use Plack::Response;

use Web::Machine::FSM;
use Web::Machine::Util qw[ inflate_headers ];

{
    package NoEtag;

    use base 'Web::Machine::Resource';

    sub allowed_methods { [qw[ GET ]] }

    sub content_types_provided {
        [
            {
                'text/plain' => sub { return 'x' }
            }
        ];
    }
}

my $request = inflate_headers(
    Plack::Request->new(
        {
            REQUEST_METHOD     => 'GET',
            CONTENT_TYPE       => 'text/plain',
            HTTP_IF_NONE_MATCH => 'foobar',
        }
    )
);

my $r = NoEtag->new(
    request  => $request,
    response => Plack::Response->new
);

my $fsm = Web::Machine::FSM->new;

my $response = $fsm->run($r);
ok( $response, 'got a response' );

done_testing;
