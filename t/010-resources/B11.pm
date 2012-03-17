package B11;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub known_methods { [qw[ GET ]] }

sub uri_too_long { 1 }

1;