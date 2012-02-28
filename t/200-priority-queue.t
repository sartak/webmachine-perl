#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Web::Machine::Util::PriorityList');
}

my $q = Web::Machine::Util::PriorityList->new;
isa_ok($q, 'Web::Machine::Util::PriorityList');

$q->add( 1.0, "foo" );
$q->add( 2.0, "bar" );
$q->add( 3.0, "baz" );
$q->add( 3.0, "foobaz" );
$q->add( 2.5, "gorch" );

is_deeply($q->get(2.5), ["gorch"], '... got the right item for the priority');
is($q->priority_of("foo"), 1.0, '... got the right priority for the item');

is_deeply($q->get(3.0), ["baz", "foobaz"], '... got the right item for the priority');

$q->add_header_value('application/xml;q=0.7');

is_deeply($q->get(0.7), ["application/xml"], '... got the right item for the priority');
is($q->priority_of("application/xml"), 0.7, '... got the right priority for the item');

is_deeply(
    [ $q->iterable ],
    [
        [ 0.7, 'application/xml' ],
        [ 1, 'foo' ],
        [ 2, 'bar' ],
        [ 2.5, 'gorch' ],
        [ 3, 'baz' ],
        [ 3, 'foobaz' ]
    ],
    '... got the iterable form'
);

done_testing;