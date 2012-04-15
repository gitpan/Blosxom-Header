use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({ '-foo' => 'bar' });
    ok $header->exists( '-foo' ),  'exists returns true';
    ok !$header->exists( '-bar' ), 'exists returns false';
    ok $header->exists( 'Foo' ),   'exists, not case-sensitive';
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        foo  => 'baz',
    });
    warning_is { $header->exists( 'foo' ) }
        '2 elements specify the foo header.';
}

done_testing;
