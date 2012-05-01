#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Web::Machine::Util' => 'bind_path');
}

is_deeply( [ bind_path( '/test/:foo/:bar', '/test/1/2' ) ], [ 1, 2 ], '... got the right bindings' );
is_deeply( [ bind_path( '/test/*', '/test/1/2' ) ], [ 1, 2 ], '... got the right bindings' );
is_deeply( [ bind_path( '/user/:id/:action', '/user/1/edit' ) ], [ 1, 'edit' ], '... got the right bindings' );
is_deeply( [ bind_path( '/:id', '/201' ) ], [ 201 ], '... got the right bindings' );
is_deeply( [ bind_path( '/tree/*', '/tree/_,_,_/_,_,_/' ) ], [ '_,_,_', '_,_,_' ], '... got the right bindings' );

is( scalar bind_path( '/:id', '/201' ), 201, '... got the right bindings (context sensitive)' );
is( scalar bind_path( '/user/:id/:action', '/user/1/edit' ), 2, '... got the right bindings (context sensitive)' );

is_deeply( [ bind_path( '/:id', '/' ) ], [], '... binding failed, nothing returned' );
is_deeply( [ bind_path( '/user/:id/:action', '/foo/bar' ) ], [], '... binding failed, nothing returned' );


done_testing;