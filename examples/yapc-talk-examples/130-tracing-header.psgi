#!perl

use strict;
use warnings;

use Web::Machine;

=pod

=cut

{
    package YAPC::NA::2012::Example130::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [ { 'text/html' => 'to_html' } ] }

    sub to_html { '<html><body><h1>Hello World</h1></body></html>' }
}

Web::Machine->new(
    resource => 'YAPC::NA::2012::Example130::Resource',
    tracing  => 1
)->to_app;
