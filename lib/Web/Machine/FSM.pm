package Web::Machine::FSM;

use strict;
use warnings;

use Try::Tiny;
use Sub::Identify qw[ sub_name ];

use Web::Machine::FSM::States qw[
    start_state
    is_status_code
    is_new_state
];

sub new { bless {} => shift }

sub run {
    my ( $self, $resource ) = @_;

    my $request  = $resource->request;
    my $response = $resource->response;
    my $metadata = {};

    my $state = start_state;

    try {
        while (1) {
            warn "entering " . sub_name( $state ) . "\n";
            my $result = $state->( $resource, $request, $response, $metadata );
            if ( ! ref $result ) {
                warn "! ERROR with " . ($result || 'undef') . "\n";
                $response->status( 500 );
                $response->body( "Got bad state: " . ($result || 'undef') );
                last;
            }
            elsif ( is_status_code( $result ) ) {
                warn ".. terminating with " . ${ $result } . "\n";
                $response->status( ${ $result } );
                $resource->finish_request;
                last;
            }
            elsif ( is_new_state( $result ) ) {
                warn "-> transitioning to " . sub_name( $result ) . "\n";
                $state = $result;
            }
        }
    } catch {
        $response->status( 500 );
        $response->body( $_ );
    };

    $response;
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM;

=head1 DESCRIPTION

