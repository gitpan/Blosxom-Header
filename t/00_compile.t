use strict;
use Test::More tests => 2;

BEGIN {
    use_ok 'Blosxom::Header';
}

can_ok 'Blosxom::Header', qw( instance new has_instance TIEHASH );
