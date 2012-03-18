package H7;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub content_types_provided { [ { 'text/plain' => sub {} }, { 'application/json' => sub {} } ] }
sub languages_provided     { [qw[ de fr ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} }, { 'iso-8859-5' => sub {} } ] }
sub encodings_provided     { +{ 'gzip' => sub {}, 'deflate' => sub {} } }

sub resource_exists { 0 }

1;