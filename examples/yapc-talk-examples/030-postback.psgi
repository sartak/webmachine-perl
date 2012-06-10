#!perl

use strict;
use warnings;

use Web::Machine;


{
    package YAPC::NA::2012::Example030::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    our @MESSAGES = ();
    sub save_message { push @MESSAGES => $_[1] }
    sub get_messages { @MESSAGES }

    sub allowed_methods        { [qw[ GET POST ]] }
    sub content_types_provided { [ { 'text/html' => 'to_html' } ] }

    sub to_html {
        my $self = shift;
        '<html><body><form method="POST"><input type="text" name="message" />'
        . '<input type="submit" /></form><hr/><ul>'
        . (join '' => map { '<li>' . $_ . '</li>' } $self->get_messages)
        . '</ul></body></html>'
    }

    sub process_post {
        my $self = shift;
        $self->save_message( $self->request->param('message') );
        $self->response->header('Location' => '/');
        return \301;
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example030::Resource' )->to_app;
