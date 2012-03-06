package Web::Machine::FSM;
use Moose;

use Try::Tiny;
use Web::Machine::FSM::States qw[
    start_state
    is_status_code
    is_new_state
    get_state_name
    get_state_desc
];

sub run {
    my ( $self, $resource ) = @_;

    my $DEBUG = $ENV{'WM_DEBUG'};

    my $request  = $resource->request;
    my $response = $resource->response;
    my $metadata = {};

    my $state = start_state;

    try {
        while (1) {
            warn "entering " . get_state_name( $state ) . " (" . get_state_desc( $state ) . ")\n" if $DEBUG;
            my $result = $state->( $resource, $request, $response, $metadata );
            if ( ! ref $result ) {
                warn "! ERROR with " . ($result || 'undef') . "\n" if $DEBUG;
                $response->status( 500 );
                $response->body( "Got bad state: " . ($result || 'undef') );
                last;
            }
            elsif ( is_status_code( $result ) ) {
                warn ".. terminating with " . ${ $result } . "\n" if $DEBUG;
                $response->status( ${ $result } );
                $resource->finish_request;

                if ( $DEBUG ) {
                    require Data::Dumper;
                    warn Data::Dumper::Dumper( $request->env );
                    warn Data::Dumper::Dumper( $response->finalize );
                }

                last;
            }
            elsif ( is_new_state( $result ) ) {
                warn "-> transitioning to " . get_state_name( $result ) . "\n" if $DEBUG;
                $state = $result;
            }
        }
    } catch {
        warn $_ if $DEBUG;
        $response->status( 500 );
        $response->body( $_ );
    };

    $response;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM;

=head1 DESCRIPTION

