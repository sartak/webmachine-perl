package B10;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods { [qw[ PUT DELETE ]] }

1;