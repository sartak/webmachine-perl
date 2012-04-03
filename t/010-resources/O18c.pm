package O18c;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods        { [qw[ GET HEAD DELETE ]] }
sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ de ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }
sub encodings_provided     { +{ 'gzip' => sub {} } }

sub generate_etag { '0xDEADBEEF' }

sub last_modified { '18 Mar 2005 15:45:00 GMT' }

sub delete_resource {
    (shift)->response->body('HELLO WORLD');
    1;
}
sub delete_completed { 1 }

1;

1;