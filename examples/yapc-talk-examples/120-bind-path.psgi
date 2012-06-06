#!perl

use strict;
use warnings;

use Web::Machine;

=pod

curl -v http://0:5000/

curl -v http://0:5000/user/edit/100

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
        if ( my ($controller, $action, $id) = bind_path('/:controller/:action/:id', $self->request->path_info) ) {
            return "<html><body>You are performing the '$action' action on the '$controller' controller for '$id'.</body></html>";
        }
        else {
            return "<html><body>Please specify and controller, action and an id.</body></html>";
        }
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example120::Resource' )->to_app;
