package H7f;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ de ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }
sub encodings_provided     { +{ 'gzip' => sub {} } }

sub variances { [qw[ Accept Accept-Language ]] }

sub resource_exists { 0 }

1;