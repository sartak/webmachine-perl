#!perl

use strict;
use warnings;

use Web::Machine;

=pod

This demostrates how you can easily handle situations
like the site being down in a reasonably elegant way.

touch site_down
rm site_down

=cut

{
    package YAPC::NA::2012::Example110::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [
        { 'text/html' => 'to_html' },
    ] }

    sub to_html { '<html><body><h1>Hello World</h1></body></html>' }

    sub service_available {
        my $self = shift;
        return 1 unless -e './site_down';
        $self->response->body(['<html><body><h1>Service Unavailable</h1>Please come back later.</body></html>']);
        0;
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example110::Resource' )->to_app;
