#!perl

use strict;
use warnings;
use FindBin;

use Web::Machine;

BEGIN {
    eval {
        require( "$FindBin::Bin/030-postback.psgi" ) &&
        require( "$FindBin::Bin/031-postback-w-json.psgi" ) &&
        require( "$FindBin::Bin/032-postback-w-auth.psgi" )
    }
}

{
    package YAPC::NA::2012::Example033::Resource;
    use strict;
    use warnings;
    use JSON::XS qw[ encode_json ];
    use Web::Machine::Util qw[ create_header ];

    use base 'YAPC::NA::2012::Example032::Resource';

    sub content_types_provided {
        my $self  = shift;
        my $types = $self->SUPER::content_types_provided;
        push @$types => { 'application/json' => 'to_json' };
        $types;
    }

    sub to_json {
        my $self = shift;
        $self->response->header(
            'Link' => create_header(
                'LinkHeader' => [ '/', ('content-type' => 'text/html') ]
            )
        );
        encode_json([ $self->get_messages ]);
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example033::Resource' )->to_app;
