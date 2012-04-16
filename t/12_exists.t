use strict;
use Test::More;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({ '-foo' => 'bar' });
    ok $header->exists( '-foo' ),  'exists returns true';
    ok !$header->exists( '-bar' ), 'exists returns false';
    ok $header->exists( 'Foo' ),   'exists, not case-sensitive';
}

done_testing;
