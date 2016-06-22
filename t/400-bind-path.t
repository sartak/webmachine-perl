#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util' => 'bind_path');
}

is_deeply( [ bind_path( '/test/:foo/:bar', '/test/1/2' ) ], [ 1, 2 ], '... got the right bindings' );
is_deeply( [ bind_path( '/test/:foo/:bar', '/test/1/0' ) ], [ 1, 0 ], '... got the right bindings (with false part segement)' );
is( bind_path( '/test/:foo/:bar', '/test/1/2/3' ), undef, '... binding failed, nothing returned' );

is_deeply( [ bind_path( '/test/*', '/test/1/2' ) ], [ 1, 2 ], '... got the right bindings' );
is_deeply( [ bind_path( '/test/*', '/test/1' ) ], [ 1 ], '... got the right bindings' );
is_deeply( [ bind_path( '/test/*', '/test/' ) ], [], '... got the right bindings (which is nothing)' );
isnt( bind_path( '/test/*', '/test/' ), undef, '... got the right bindings (which is nothing) (doublecheck)' );
is_deeply( [ bind_path( '/tree/*', '/tree/_,_,_/_,_,_/' ) ], [ '_,_,_', '_,_,_' ], '... got the right bindings' );

is( scalar bind_path( '/:id', '/201' ), 201, '... got the right bindings (context sensitive)' );
is_deeply( [ bind_path( '/:id', '/201' ) ], [ 201 ], '... got the right bindings' );
is_deeply( [ bind_path( '/?:id', '/201' ) ], [ 201 ], '... got the right bindings' );
is_deeply( [ bind_path( '/?:id', '/' ) ], [], '... got the right bindings (which is nothing)' );
isnt( bind_path( '/?:id', '/' ), undef, '... got the right bindings (which is nothing) (doublecheck)' );
is( scalar bind_path( '/?:id', '/' ), 0, '... got the right bindings (which is nothing) (doublecheck)' );
is( bind_path( '/?:id', '/201/100' ), undef, '... binding failed, nothing returned' );
is( scalar bind_path( '/?:id', '/201/100' ), undef, '... binding failed, nothing returned' );

is( scalar bind_path( '/user/:id/:action', '/user/1/edit' ), 2, '... got the right bindings (context sensitive)' );
is_deeply( [ bind_path( '/user/:id/:action', '/user/1/edit' ) ], [ 1, 'edit' ], '... got the right bindings' );
is( bind_path( '/user/:id/:action', '/foo/bar' ), undef, '... binding failed, nothing returned' );
is( bind_path( '/user/:id/:action', '/user/foo/' ), undef, '... binding failed, nothing returned' );
is_deeply( [ bind_path( '/user/:id/?:action', '/user/foo/' ) ], [ 'foo' ], '... binding succeeded with optional param' );
is_deeply( [ bind_path( '/user/:id/?:action', '/user/foo/bar' ) ], [ 'foo', 'bar' ], '... binding succeeded with optional param' );
is( bind_path( '/user/:id/?:action', '/user/foo/bar/baz' ), undef, '... binding failed, nothing returned' );

done_testing;
