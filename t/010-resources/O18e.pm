package O18e;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub content_types_provided { [ { 'text/plain' => 'handle_plain_text' }] }

sub handle_plain_text { 'HELLO WORLD' }

1;
