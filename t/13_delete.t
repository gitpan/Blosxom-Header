use strict;
use Blosxom::Header;
use Test::More;

{
    my $header = Blosxom::Header->new({
        -foo => 'bar',
        -bar => 'baz',
    });

    $header->delete( '-foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete';

    $header->delete( '-foo' );
    is_deeply $header->{header}, { -bar => 'baz' }, 'delete nothing';
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
