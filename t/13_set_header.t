use strict;
use Test::More;
use Blosxom::Header qw(set_header);

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, '-bar' => 'baz' );
    is_deeply $header_ref, { '-foo' => 'bar', 'bar' => 'baz' };
}

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, '-bar' => q{} );
    is_deeply $header_ref, { '-foo' => 'bar', 'bar' => q{} }, 'set empty string';
}

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, '-foo' => 'baz' );
    is_deeply $header_ref, { 'foo' => 'baz' }, 'set overwrite';
}

{
    my $header_ref = { '-foo' => 'bar' };
    set_header( $header_ref, Foo => 'baz' );
    is_deeply $header_ref, { 'foo' => 'baz' }, 'set case-sensitive';
}

{
    my $header_ref = { foo => 'bar' };
    set_header( $header_ref, foo => [ 'bar', 'baz' ] );
    is_deeply $header_ref, { 'foo' => [ 'bar', 'baz' ] }, 'set arrayref';
}

{
    my $header_ref = { foo => 'bar', '-foo' => 'baz' };
    set_header( $header_ref, foo => 'qux' );
    is_deeply $header_ref, { 'foo' => 'qux' };
}

done_testing;
