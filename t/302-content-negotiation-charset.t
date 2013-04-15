#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util::ContentNegotiation', 'choose_charset');
}

is(
    choose_charset( [], 'ISO-8859-1' ),
    1,
    '... got a 1 back (no choices)'
);

is(
    choose_charset( [{ "UTF-8", sub {} },{ "US-ASCII", sub {} }], "US-ASCII, UTF-8" ),
    'US-ASCII',
    '... got the right charset back'
);

is(
    choose_charset( [{ "UTF-8", sub {} },{ "US-ASCII", sub {} }], "US-ASCII;q=0.7, UTF-8" ),
    'UTF-8',
    '... got the right charset back'
);

is(
   choose_charset( [{ "UTF-8", sub {} },{ "US-ASCII", sub {} }], 'ISO-8859-1' ),
   'UTF-8',
   '... got default back when it is acceptable'
);

is(
    choose_charset( [{ "UtF-8", sub {} },{ "US-ASCII", sub {} }], "iso-8859-1, utf-8" ),
    'UtF-8',
    '... got the right charset back'
);

done_testing;
