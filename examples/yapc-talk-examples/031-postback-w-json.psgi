#!perl

use strict;
use warnings;
use FindBin;

use Web::Machine;

BEGIN { eval { require( "$FindBin::Bin/030-postback.psgi" ) } }

{
    package YAPC::NA::2012::Example031::Resource;
    use strict;
    use warnings;
    use JSON::XS ();

    use base 'YAPC::NA::2012::Example030::Resource';

    sub allowed_methods        { [qw[ GET PUT POST ]] }
    sub content_types_accepted { [ { 'application/json' => 'from_json' } ] }

    sub from_json {
        my $self = shift;
        $self->save_message( JSON::XS->new->allow_nonref->decode( $self->request->content ) );
    }

    sub process_post {
        my $self = shift;
        return \415 unless $self->request->header('Content-Type')->match('application/x-www-form-urlencoded');
        $self->SUPER::process_post;
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example031::Resource' )->to_app;
