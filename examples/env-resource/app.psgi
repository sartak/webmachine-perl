#!perl

use strict;
use warnings;

use Web::Machine;

=pod

Partial port of the webmachine example from here:

https://bitbucket.org/bryan/wmexamples/src/fa8104e75550/src/env_resource.erl

=cut

{
    package Env::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    use JSON::XS ();
    my $JSON = JSON::XS->new->allow_nonref->pretty;

    sub new {
        my $self = shift->SUPER::new( @_ );
        $self->{'context'} = undef;
        $self;
    }

    sub context {
        my $self = shift;
        $self->{'context'} = shift if @_;
        $self->{'context'}
    }

    sub content_types_provided { [{ 'application/json' => 'to_json'   }] }
    sub content_types_accepted { [{ 'application/json' => 'from_json' }] }

    sub allowed_methods {
        return [
            qw[ GET HEAD PUT ],
            ((shift)->request->path_info eq '/' ? () : 'DELETE')
        ];
    }

    sub resource_exists {
        my $self = shift;
        my $var  = $self->_get_path;
        if ( $var ) {
            $self->context( $ENV{ $var } ) if exists $ENV{ $var };
        }
        else {
            $self->context( { map { $_ => $ENV{ $_ } } keys %ENV } );
        }
    }

    sub to_json { $JSON->encode( (shift)->context ) }

    sub from_json {
        my $self = shift;
        my $var  = $self->_get_path;
        my $data = $JSON->decode( $self->request->content );
        if ( $var ) {
            $ENV{ $var } = $data;
        }
        else {
            map { $ENV{ $_ } = $data->{ $_ } } keys %$data;
        }
    }

    sub delete_resource { delete $ENV{ (shift)->_get_path } }

    # ...

    sub _get_path {
        my $self = shift;
        my $var  = $self->request->path_info;
        $var =~ s/^\///;
        $var;
    }
}

Web::Machine->new( resource => 'Env::Resource' )->to_app
