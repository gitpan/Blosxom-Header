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
    my @cookies = ( 'foo', 'bar' );
    my $header = Blosxom::Header->new({ -cookie => \@cookies });
    is $header->get( 'Set-Cookie' ), \@cookies, 'get cookie in scalar context';

    my @got = $header->get( 'Set-Cookie' );
    is_deeply \@got, [ 'foo', 'bar' ], 'get cookie in list context';
}

done_testing;
