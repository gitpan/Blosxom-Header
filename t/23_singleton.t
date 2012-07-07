use strict;
use Blosxom::Header;
use Test::More tests => 5;

{
    package blosxom;
    our $header = {};
}

ok( !Blosxom::Header->has_instance, 'no Blosxom::Header instance yet' );

my $h1 = Blosxom::Header->instance;
ok( $h1, 'created Blosxom::Header instance 1' );

my $h2 = Blosxom::Header->instance;
ok( $h2, 'created Blosxom::Header instance 2' );

is( $h1, $h2, 'both instances are the same object' );
is( Blosxom::Header->has_instance, $h1, 'Blosxom::Header has instance' );
