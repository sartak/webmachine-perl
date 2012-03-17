package B12;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub known_methods { [qw[ PUT DELETE ]] }

1;