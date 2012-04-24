use strict;
use Blosxom::Header;
use Test::More;

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
    });

    is_deeply [ $header->delete( '-foo' ) ], [ 'bar' ];
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete';

    is $header->delete( '-foo' ), undef;
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete nothing';
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    });

    is_deeply [ $header->delete( '-foo', '-bar' ) ], [ qw/bar baz/ ];
    is_deeply $header->{header}, { -baz => 'qux' }, 'delete multiple elements';
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
