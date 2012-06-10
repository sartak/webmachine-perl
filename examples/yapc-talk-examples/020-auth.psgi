#!perl

use strict;
use warnings;

use Web::Machine;

=pod

=cut

{
    package YAPC::NA::2012::Example020::Resource;
    use strict;
    use warnings;
    use Web::Machine::Util qw[ create_header ];

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [ { 'text/html' => 'to_html' } ] }

    sub to_html { '<html><body><h1>Hello World</h1></body></html>' }

    sub is_authorized {
        my ($self, $auth_header) = @_;
        if ( $auth_header ) {
            return 1 if $auth_header->username eq 'foo' && $auth_header->password eq 'bar';
        }
        return create_header( 'WWWAuthenticate' => [ 'Basic' => ( realm => 'Webmachine' ) ] );
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example020::Resource' )->to_app;
