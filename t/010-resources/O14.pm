package O14;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods        { [qw[ GET HEAD PUT ]] }
sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ de ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }

sub generate_etag { '0xDEADBEEF' }

sub last_modified { '18 Mar 2005 15:45:00 GMT' }

sub is_conflict { 1 }

1;