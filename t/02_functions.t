use strict;
use Test::More;
use Blosxom::Header qw(:all);

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, bar => 'baz' );
    is_deeply $header_ref, { '-foo' => 'bar', 'bar' => 'baz' };
}

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, -foo => q{} );
    is_deeply $header_ref, { '-foo' => q{} }, 'set empty string';
}

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, -foo => 'baz' );
    is_deeply $header_ref, { '-foo' => 'baz' }, 'set overwrite';
}

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, Foo => 'baz' );
    is_deeply $header_ref, { '-foo' => 'baz' }, 'set case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar' };
    is get_header( $header_ref, '-foo' ), 'bar';
}

{
    my $header_ref = { '-foo' => 'bar' };
    is get_header( $header_ref, 'Foo' ), 'bar', 'get case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    delete_header( $header_ref, '-foo' );
    is_deeply $header_ref, { '-bar' => 'baz' };
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    delete_header( $header_ref, 'Foo' );
    is_deeply $header_ref, { '-bar' => 'baz' }, 'delete case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar', 'foo' => 'baz', '-bar' => 'baz' };
    delete_header( $header_ref, 'Foo' );
    is_deeply $header_ref, { '-bar' => 'baz' }, 'delete multiple values';
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    ok exists_header( $header_ref, '-foo' );
    ok !exists_header( $header_ref, 'baz' );
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    ok exists_header( $header_ref, 'Foo' ), 'exists case-sensitive';
}

done_testing;
