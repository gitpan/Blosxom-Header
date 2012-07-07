use strict;
use Test::More tests => 4;

BEGIN {
    use_ok 'Blosxom::Header';
    use_ok 'Blosxom::Header::Adapter';
}

can_ok 'Blosxom::Header', qw( instance has_instance );
can_ok 'Blosxom::Header::Adapter', qw( TIEHASH );
