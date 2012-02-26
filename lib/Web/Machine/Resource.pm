package Web::Machine::Resource;
use Moose::Role;

use Web::Machine::Util;

has 'request' => (
    is       => 'ro',
    isa      => 'Plack::Request',
    required => 1
);

has 'response' => (
    is       => 'ro',
    isa      => 'Plack::Response',
    required => 1
);

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
sub charsets_provided         { undef }
sub languages_provided        { [] }
sub language_chosen           { 'en_US' }
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

requires 'to_html';

no Moose::Role; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Resource;

=head1 DESCRIPTION
