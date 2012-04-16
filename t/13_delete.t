use strict;
use Blosxom::Header;
use Test::More;

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
    });

    my @values = $header->delete( '-foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete';
    is_deeply \@values, [ 'bar' ];

    @values = $header->delete( '-foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete nothing';
    is_deeply \@values, [ undef ];
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    });

    my @values = $header->delete( '-foo', '-bar' );
    is_deeply $header->{header}, { -baz => 'qux' }, 'delete multiple elements';
    is_deeply \@values, [ 'bar', 'baz' ];
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
    });

    $header->delete( 'Foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete, not case-sensitive';
}

done_testing;
