#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util', 'pair_key');
    use_ok('Web::Machine::Util::ContentNegotiation', 'match_acceptable_media_type');
}

is(
    pair_key(
        match_acceptable_media_type(
            'application/json',
            [ { 'application/json' => sub {} } ],
        )
    ),
    'application/json',
    '... matched type'
);

is(
    pair_key(
        match_acceptable_media_type(
            'application/json',
            [ { 'text/html'  => sub {} }, { 'text/xml' => sub {} }, { '*/*' => sub {} } ],
        )
    ),
    '*/*',
    '... matched type'
);

done_testing;
