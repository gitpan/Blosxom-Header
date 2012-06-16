use strict;
use Test::More tests => 6;

BEGIN {
    my @methods = qw( header_get header_set header_exists header_delete );
    use_ok 'Blosxom::Header', ( '$Header', @methods );
    can_ok __PACKAGE__, @methods;
}

ok( Blosxom::Header->has_instance );
ok $Header;
is $Header, Blosxom::Header->has_instance;

my $h = Blosxom::Header->instance;
is $h, $Header;

