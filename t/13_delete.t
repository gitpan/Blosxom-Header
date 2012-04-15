use strict;
use Test::More;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
    });
    $header->delete( '-foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete';
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
    });
    $header->delete( 'Foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete, not case-sensitive';
}

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        foo  => 'baz',
        -bar => 'baz'
    });
    $header->delete( 'Foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete multiple elements';
}

done_testing;
