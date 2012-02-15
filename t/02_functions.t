use strict;
use Test::More;
use Blosxom::Header qw(set_header get_header remove_header has_header);

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
    remove_header( $header_ref, '-foo' );
    is_deeply $header_ref, { '-bar' => 'baz' };
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    remove_header( $header_ref, 'Foo' );
    is_deeply $header_ref, { '-bar' => 'baz' }, 'remove case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar', 'foo' => 'baz', '-bar' => 'baz' };
    remove_header( $header_ref, 'Foo' );
    is_deeply $header_ref, { '-bar' => 'baz' }, 'remove multiple values';
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    ok has_header( $header_ref, '-foo' );
    ok !has_header( $header_ref, 'baz' );
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    ok has_header( $header_ref, 'Foo' ), 'has case-sensitive';
}

done_testing;
