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

    use Web::Machine::Util qw[ bind_path ];

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
        if ( my $var = bind_path( '/:id', $self->request->path_info ) ) {
            $self->context( $ENV{ $var } ) if exists $ENV{ $var };
        }
        else {
            $self->context( { map { $_ => $ENV{ $_ } } keys %ENV } );
        }
    }

    sub to_json { $JSON->encode( (shift)->context ) }

    sub from_json {
        my $self = shift;
        my $data = $JSON->decode( $self->request->content );
        if ( my $var = bind_path( '/:id', $self->request->path_info ) ) {
            $ENV{ $var } = $data;
        }
        else {
            map { $ENV{ $_ } = $data->{ $_ } } keys %$data;
        }
    }

    sub delete_resource { delete $ENV{ bind_path( '/:id', (shift)->request->path_info ) } }
}

Web::Machine->new( resource => 'Env::Resource' )->to_app
