use strict;
use Test::More;
use Blosxom::Header qw(delete_header);

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
    is_deeply $header_ref, { '-bar' => 'baz' }, 'delete multiple elements';
}

done_testing;
