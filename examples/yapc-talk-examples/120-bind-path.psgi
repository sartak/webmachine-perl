#!perl

use strict;
use warnings;

use Web::Machine;

=pod

curl -v http://0:5000/

curl -v http://0:5000/edit/100

=cut

{
    package YAPC::NA::2012::Example120::Resource;
    use strict;
    use warnings;
    use Web::Machine::Util qw[ bind_path ];

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $self = shift;
        if ( my ($action, $id) = bind_path( '/:action/:id', $self->request->path_info ) ) {
            return "<html><body><h1>action('$action') id('$id')</h1></body></html>";
        }
        else {
            return \404;
        }
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example120::Resource' )->to_app;
