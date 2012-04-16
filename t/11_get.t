use strict;
use Blosxom::Header;
use Test::More;

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    is $header->get( '-foo' ), 'bar';
    is $header->get( 'Foo' ),  'bar', 'get, not case-sensitive';
    is $header->get( '-bar' ), undef, 'get undef';
}

{
    my $header = Blosxom::Header->new({ -cookie => [ 'foo', 'bar' ] });
    is $header->get( 'Set-Cookie' ), 'foo', 'get cookie in scalar context';

    my @cookies = $header->get( 'Set-Cookie' );
    is_deeply \@cookies, [ 'foo', 'bar' ], 'get cookie in list context';
}

done_testing;
