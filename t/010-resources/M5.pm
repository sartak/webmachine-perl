package M5;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods        { [qw[ GET HEAD PUT ]] }
sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ en ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }
sub resource_exists        { 0 }
sub previously_existed     { 1 }

1;