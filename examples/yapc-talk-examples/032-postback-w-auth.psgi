#!perl

use strict;
use warnings;
use FindBin;

use Web::Machine;

BEGIN {
    eval {
        require( "$FindBin::Bin/030-postback.psgi" ) &&
        require( "$FindBin::Bin/031-postback-w-json.psgi" )
    }
}

{
    package YAPC::NA::2012::Example032::Resource;
    use strict;
    use warnings;
    use Web::Machine::Util qw[ create_header ];

    use base 'YAPC::NA::2012::Example031::Resource';

    sub is_authorized {
        my ($self, $auth_header) = @_;
        return 1 if $self->request->method ne 'PUT';
        if ( $auth_header ) {
            return 1 if $auth_header->username eq 'foo' && $auth_header->password eq 'bar';
        }
        return create_header( 'WWWAuthenticate' => [ 'Basic' => ( realm => 'Webmachine' ) ] );
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example032::Resource' )->to_app;
