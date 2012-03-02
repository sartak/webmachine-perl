#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util::ContentNegotiation', 'choose_encoding');
}

ok(!defined( choose_encoding( {}, 'identity, gzip' ) ), '... got nothing back');
ok(!defined( choose_encoding( { "gzip" => sub {} }, 'identity' ) ), '... got nothing back');

is(
    choose_encoding( { "gzip" => sub {}, "identity" => sub {} }, "identity" ),
    'identity',
    '... got the right encoding back'
);

is(
    choose_encoding( { "gzip" => sub {} }, "identity, gzip" ),
    'gzip',
    '... got the right encoding back'
);

is(
    choose_encoding( { "gzip" => sub {}, "identity" => sub {} }, "gzip, identity;q=0.7" ),
    'gzip',
    '... got the right encoding back'
);


done_testing;