package Web::Machine::Resource;

use strict;
use warnings;

use Scalar::Util qw[ blessed ];
use Carp         qw[ confess ];

use Web::Machine::Util;

sub new {
    my $class  = shift;
    my %args = ref $_[0] ? %{ $_[0] } : @_;

    (exists $args{'request'} && blessed $args{'request'} && $args{'request'}->isa('Plack::Request'))
        || confess "The 'request' parameter is required and must be a Plack::Request";

    (exists $args{'response'} && blessed $args{'response'} && $args{'response'}->isa('Plack::Response'))
        || confess "The 'response' parameter is required and must be a Plack::Response";

    bless { %args } => $class;
}

sub request  { (shift)->{'request'}  }
sub response { (shift)->{'response'} }

sub resource_exists           { true  }
sub service_available         { true  }
sub is_authorized             { true  }
sub forbidden                 { false }
sub allow_missing_post        { false }
sub malformed_request         { false }
sub uri_too_long              { false }
sub known_content_type        { true  }
sub valid_content_headers     { true  }
sub valid_entity_length       { true  }
sub options                   { +{}   }
sub allowed_methods           { [qw[ GET HEAD ]] }
sub known_methods             { [qw[ GET HEAD POST PUT DELETE TRACE CONNECT OPTIONS ]]}
sub delete_resource           { false }
sub delete_completed          { true  }
sub post_is_create            { false }
sub create_path               { undef }
sub process_post              { false }
sub content_types_provided    { [ [ 'text/html' => 'to_html' ] ] }
sub content_types_accepted    { [] }
sub charsets_provided         { [] }
sub languages_provided        { [] }
sub encodings_provided        { [ { 'identity' => sub { shift } } ] }
sub variances                 { [] }
sub is_conflict               { false }
sub multiple_choices          { false }
sub previously_existed        { false }
sub moved_permanently         { false }
sub moved_temporarily         { false }
sub last_modified             { undef }
sub expires                   { undef }
sub generate_etag             { undef }
sub finish_request            {}

sub to_html {
    q[<html></html>]
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Resource;

=head1 DESCRIPTION
