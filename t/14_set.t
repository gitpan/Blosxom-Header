use strict;
use Test::More;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( -bar => 'baz' );
    is_deeply $header->{header}, { -foo => 'bar', bar => 'baz' }, 'delete';
}

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( -bar => q{} );
    my $expected = { -foo => 'bar', bar => q{} };
    is_deeply $header->{header}, $expected, 'set empty string';
}

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( -foo => 'baz' );
    is_deeply $header->{header}, { foo => 'baz' }, 'set overwrite';
}

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( Foo => 'baz' );
    is_deeply $header->{header}, { foo => 'baz' }, 'set, not case-sensitive';
}

{
    my $header = Blosxom::Header->new({ cookie => 'bar' });
    $header->set( cookie => [ 'bar', 'baz' ] );
    is_deeply $header->{header}, { cookie => [ 'bar', 'baz' ] }, 'set arrayref';
}

{
    my $header = Blosxom::Header->new({
        foo  => 'bar',
        -foo => 'baz',
    });
    $header->set( Foo => 'qux' );
    is_deeply $header->{header}, { foo => 'qux' }, 'set';
}

done_testing;
