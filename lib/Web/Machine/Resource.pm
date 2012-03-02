package Web::Machine::Resource;
use Moose::Role;

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

sub resource_exists           { 1 }
sub service_available         { 1 }
sub is_authorized             { 1 }
sub forbidden                 { 0 }
sub allow_missing_post        { 0 }
sub malformed_request         { 0 }
sub uri_too_long              { 0 }
sub known_content_type        { 1 }
sub valid_content_headers     { 1 }
sub valid_entity_length       { 1 }
sub options                   { +{} }
sub allowed_methods           { [qw[ GET HEAD ]] }
sub known_methods             { [qw[ GET HEAD POST PUT DELETE TRACE CONNECT OPTIONS ]]}
sub delete_resource           { 0 }
sub delete_completed          { 1 }
sub post_is_create            { 0 }
sub create_path               { undef }
sub process_post              { 0 }
sub content_types_provided    { [ [ 'text/html' => 'to_html' ] ] }
sub content_types_accepted    { [] }
sub charsets_provided         { [] }
sub languages_provided        { [] }
sub encodings_provided        { { 'identity' => sub { shift } } }
sub variances                 { [] }
sub is_conflict               { 0 }
sub multiple_choices          { 0 }
sub previously_existed        { 0 }
sub moved_permanently         { 0 }
sub moved_temporarily         { 0 }
sub last_modified             { undef }
sub expires                   { undef }
sub generate_etag             { undef }
sub finish_request            {}

no Moose::Role; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Resource;

=head1 DESCRIPTION
