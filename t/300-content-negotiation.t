#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Web::Machine::Util::ContentNegotiation', 'choose_media_type');
}

ok(!defined( choose_media_type( [], '*/*' ) ), '... got nothing back');
ok(!defined( choose_media_type( [ "text/html" ], 'application/json' ) ), '... got nothing back');

is(
    choose_media_type(
        ["text/html", "application/xml"],
        "application/xml, text/html, */*"
    ),
    'application/xml',
    '... got the right media type back'
);

is(
    choose_media_type(
        ["text/html", "text/html;charset=iso8859-1" ],
        "text/html;charset=iso8859-1, application/xml"
    ),
    'text/html;charset=iso8859-1',
    '... got the right media type back'
);

is(
    choose_media_type(
        ["application/json;v=3;foo=bar", "application/json;v=2"],
        "text/html, application/json"
    ),
    'application/json;v=3;foo=bar',
    '... got the right media type back'
);

is(
    choose_media_type(
        ["text/html", "application/xml"],
        "application/xml;q=0.7, text/html, */*"
    ),
    'text/html',
    '... got the right media type back'
);

is(
    choose_media_type(
        ["text/html", "application/xml"],
        "bah"
    ),
    undef,
    '... got the right media type back'
);


done_testing;