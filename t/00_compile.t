use strict;
use Test::More tests => 7;

BEGIN {
    use_ok 'Blosxom::Header';
    use_ok 'Blosxom::Header::Adapter';
    use_ok 'Blosxom::Header::Hash';
    use_ok 'Blosxom::Header::Util';
}

can_ok 'Blosxom::Header', qw( instance has_instance );
can_ok 'Blosxom::Header::Adapter', qw( TIEHASH );
can_ok 'Blosxom::Header::Hash', qw( new );
