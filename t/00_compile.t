use strict;
use Test::More tests => 4;

BEGIN {
    use_ok 'Blosxom::Header';
    use_ok 'Blosxom::Header::Proxy';
}

can_ok 'Blosxom::Header', qw( instance has_instance );
can_ok 'Blosxom::Header::Proxy', qw( TIEHASH );
