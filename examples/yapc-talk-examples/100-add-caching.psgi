#!perl

use strict;
use warnings;

use Web::Machine;

=pod

curl -v http://0:5000/ -H 'If-Modified-Since: Sun, 27 May 2012 21:34:59 GMT'

curl -v http://0:5000/ -H 'If-Modified-Since: Sun, 27 May 2012 21:35:00 GMT'

=cut

{
    package YAPC::NA::2012::Example100::Resource;
    use strict;
    use warnings;

    use Web::Machine::Util qw[ create_date ];

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub last_modified { create_date('Sun, 27 May 2012 21:35:00 GMT') }
    sub generate_etag { '0xDEADBEEF' }

    sub to_html { '<html><body><h1>Hello World</h1></body></html>' }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example100::Resource' )->to_app;
