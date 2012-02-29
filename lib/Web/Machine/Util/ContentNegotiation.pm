package Web::Machine::Util::ContentNegotiation;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use List::AllUtils qw[ first ];
use Sub::Exporter;

use Web::Machine::Util::MediaType;
use Web::Machine::Util::MediaTypeList;
use Web::Machine::Util::PriorityList;

my @exports = qw/
    choose_media_type
/;

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

sub choose_media_type {
    my ($provided, $header) = @_;
    my $requested = Web::Machine::Util::MediaTypeList->new_from_header_list( split /\s*,\s*/ => $header );
    my $parsed_provided = [ map { Web::Machine::Util::MediaType->new_from_string( $_ ) } @$provided ];

    my $chosen;
    foreach my $requested ( $requested->iterable ) {
        my $requested_type = $requested->[1];
        $chosen = media_match( $requested_type, $parsed_provided );
        last if $chosen;
    }
    ($chosen || return)->to_string;
}

# sub choose_encoding {
#     my ($provided, $header) = @_;
#     do_choose( [ keys %$provided ], $header, 'identity' );
# }
#
# sub choose_charset {
#     my ($provided, $header) = @_;
#     if ( @$provided ) {
#         my $charsets = map {  } @$provided;
#     }
# }
#
# sub do_choose {
#     my ($choices, $header, $default) = @_;
#
#     $choices = map { lc $_ } $choices;
#
#     my $accepted         = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*, \s/ => $header );
#     my $default_priority = $accepted->priority_of( $default );
#     my $star_priority    = $accepted->priority_of( '*' );
#     my $default_ok       = ( defined $default_priority && $star_priority != 0.0 ) || $default_priority;
#     my $any_ok           = $star_priority && $star_priority > 0.0;
#
#     my $chosen = find {
#         my ($priority, $acceptable) = @$_;
#         if ( $priority == 0.0 ) {
#             $choices = grep { lc $acceptable ne $_ } @$choices;
#             false;
#         } else {
#             first { lc $acceptable eq $_ } @$choices
#         }
#     } $accepted->iterable;
#
#     ($chosen)
#         ||
#     ($any_ok && $choices->[0])
#         ||
#     ($default_ok && (first { $default eq $_ } @$choices) && $default)
# }

sub media_match {
    my ($requested, $provided) = @_;
    return $provided->[0] if $requested->matches_all;
    return first { $_->match( $requested ) } @$provided;
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM::ContentNegotiation;

=head1 DESCRIPTION

