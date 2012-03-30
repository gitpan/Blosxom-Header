use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header;

{
    my $h = Blosxom::Header->new({ '-foo' => 'bar' });
    is $h->get( '-foo' ), 'bar';
    is $h->get( '-bar' ), undef, 'get undef';
    is $h->get( 'Foo' ), 'bar', 'get case-sensitive';
}

{
    my $h = Blosxom::Header->new({ '-cookie' => [ 'foo', 'bar' ] });
    is $h->get( 'Set-Cookie' ), 'foo', 'get scalar context';

    my @values = $h->get( 'Set-Cookie' );
    is_deeply \@values, [ 'foo', 'bar' ], 'get list context';
}

{
    my $h = Blosxom::Header->new({ '-p3p' => [ 'foo', 'bar' ] });
    is $h->get( 'p3p' ), 'foo', 'get scalar context';

    my @values = $h->get( 'p3p' );
    is_deeply \@values, [ 'foo', 'bar' ], 'get list context';
}

{
    my $h = Blosxom::Header->new({ 'foo' => [ 'foo', 'bar' ] });
    warning_is { $h->get( 'foo' ) } 'The foo header must be scalar.';
}

{
    my $h = Blosxom::Header->new({ '-foo' => 'bar', 'foo' => 'baz' });
    warning_is { $h->get( 'foo' ) }
        'Multiple elements specify the foo header.';
}


done_testing;
