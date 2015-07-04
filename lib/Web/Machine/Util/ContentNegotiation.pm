package Web::Machine::Util::ContentNegotiation;
# ABSTRACT: Module to handle content negotiation

use strict;
use warnings;

our $VERSION = '0.16';

use Scalar::Util qw[ blessed ];

use Web::Machine::Util qw[
    first
    pair_key
];

use Sub::Exporter -setup => {
    exports => [qw[
        choose_media_type
        match_acceptable_media_type
        choose_language
        choose_charset
        choose_encoding
    ]]
};

my $ACTIONPACK = Web::Machine::Util::get_action_pack;
my $NEGOTIATOR = $ACTIONPACK->get_content_negotiator;

sub choose_media_type {
    my ($provided, $header) = @_;
    $NEGOTIATOR->choose_media_type( $provided, $header );
}

sub match_acceptable_media_type {
    my ($to_match, $accepted) = @_;
    my $content_type = blessed $to_match ? $to_match : $ACTIONPACK->create( 'MediaType' => $to_match );
    if ( my $acceptable = first { $content_type->match( pair_key( $_ ) ) } @$accepted ) {
        return $acceptable;
    }
    return;
}

sub choose_language {
    my ($provided, $header) = @_;
    return 1 if scalar @$provided == 0;
    $NEGOTIATOR->choose_language( $provided, $header );
}

sub choose_charset {
    my ($provided, $header) = @_;
    return 1 if scalar @$provided == 0;
    $NEGOTIATOR->choose_charset( [ map { ref $_ ? pair_key( $_ ) : $_ } @$provided ], $header );
}

sub choose_encoding {
    my ($provided, $header) = @_;
    $NEGOTIATOR->choose_encoding( [ keys %$provided ], $header );
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util::ContentNegotiation;

=head1 DESCRIPTION

This module provides a set of functions used in content negotiation.

=head1 FUNCTIONS

=over 4

=item C<choose_media_type ( $provided, $header )>

Given an ARRAY ref of media type strings and an HTTP header, this will
return the matching L<HTTP::Headers::ActionPack::MediaType> instance.

=item C<match_acceptable_media_type ( $to_match, $accepted )>

Given a media type string to match and an ARRAY ref of media type objects,
this will return the first matching one.

=item C<choose_language ( $provided, $header )>

Given a list of language codes and an HTTP header value, this will attempt
to negotiate the best language match.

=item C<choose_charset ( $provided, $header )>

Given a list of charset name and an HTTP header value, this will attempt
to negotiate the best charset match.

=item C<choose_encoding ( $provided, $header )>

Given a list of encoding name and an HTTP header value, this will attempt
to negotiate the best encoding match.

=back









