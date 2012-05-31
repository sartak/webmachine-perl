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
    use MIME::Base64;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [ { 'text/html' => 'to_html' } ] }

    sub to_html { '<html><body><h1>Hello World</h1></body></html>' }

    sub is_authorized {
        my ($self, $auth_header) = @_;
        if ( my $auth = $self->request->header('Authorization') ) {
            my ($data) = ($auth =~ /^Basic (.*)$/);
            return 1 if decode_base64( $data ) eq 'foo:bar';
            return 0;
        }
        else {
            return 'Basic realm=Webmachine';
        }
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example020::Resource' )->to_app;
