package E6;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub content_types_provided { [ { 'text/plain' => sub {} } ] }

sub languages_provided { [qw[ de fr ]] }

sub charsets_provided { [qw[ utf-8 ]] }

1;