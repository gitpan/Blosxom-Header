use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    is $header->get( '-foo' ), 'bar';
    is $header->get( 'Foo' ),  'bar', 'get, case-sensitive';
    is $header->get( '-bar' ), undef, 'get undef';
}

{
    my $header = Blosxom::Header->new({ -cookie => [ 'foo', 'bar' ] });
    is $header->get( 'cookie' ), 'foo', 'get cookie, scalar context';
    my @values = $header->get( 'cookie' );
    is_deeply \@values, [ 'foo', 'bar' ], 'get cookie, list context';
}

{
    my $header = Blosxom::Header->new({ -p3p => [ 'foo', 'bar' ] });
    is $header->get( 'p3p' ), 'foo', 'get p3p, scalar context';
    my @values = $header->get( 'p3p' );
    is_deeply \@values, [ 'foo', 'bar' ], 'get p3p, list context';
}

{
    my $header = Blosxom::Header->new({ foo => [ 'foo', 'bar' ] });
    warning_is { $header->get( 'foo' ) } 'The foo header must be scalar.';
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        foo  => 'baz',
    });
    warning_is { $header->get( 'foo' ) }
        'Multiple elements specify the foo header.';
}

done_testing;
