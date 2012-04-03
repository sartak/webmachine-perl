package P11e;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods        { [qw[ GET HEAD PUT ]] }
sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ de ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }

sub generate_etag { '0xDEADBEEF' }
sub last_modified { '18 Mar 2005 15:45:00 GMT' }

sub content_types_accepted { [ { 'text/plain' => 'accept_plain_text' } ] }

sub accept_plain_text {
    (shift)->response->location('/foo/bar');
    1;
}

1;