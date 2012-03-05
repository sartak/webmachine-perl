#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util::ContentNegotiation', 'choose_language');
}

# From http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html

is(
    choose_language( ['da', 'en-US', 'es'], "da, en-gb;q=0.8, en;q=0.7" ),
    'da',
    '... got the right language back'
);

is(
    choose_language( ['en-US', 'es'], "da, en-gb;q=0.8, en;q=0.7" ),
    'en-US',
    '... got the right language back'
);

is(
    choose_language( ['en-gb', 'da'], "da, en-gb;q=0.8, en;q=0.7" ),
    'da',
    '... got the right language back'
);

is(
    choose_language( ['en-US', 'en-gb'], "da, en-gb;q=0.8, en;q=0.7" ),
    'en-gb',
    '... got the right language back'
);

# From webmachine-ruby

is(choose_language( [], 'en' ), 1, '... got nothing back');
is(choose_language( ['en'], 'es' ), undef, '... got nothing back');

is(
    choose_language( ['en', 'en-US', 'es'], "en-US, es" ),
    'en-US',
    '... got the right language back'
);

is(
    choose_language( ['en', 'en-US', 'es'], "en-US;q=0.6, es" ),
    'es',
    '... got the right language back'
);

is(
    choose_language( ['en', 'fr', 'es'], "*" ),
    'en',
    '... got the right language back'
);

is(
    choose_language( ['en-US', 'es'], "en, fr" ),
    'en-US',
    '... got the right language back'
);

is(
    choose_language( [ 'en-US', 'ZH' ], "zh-ch, EN" ),
    'en-US',
    '... got the right language back'
);



done_testing;