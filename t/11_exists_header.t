use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header qw(exists_header);

{
    my $header_ref = { '-foo' => 'bar' };
    ok exists_header( $header_ref, '-foo' );
    ok !exists_header( $header_ref, '-bar' );
}

{
    my $header_ref = { '-foo' => 'bar' };
    ok exists_header( $header_ref, 'Foo' ), 'exists case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar', 'foo' => 'baz' };
    my $bool;
    warning_is { $bool = exists_header( $header_ref, 'foo' ) }
        '2 elements specify the foo header.';
    is $bool, 2;
}

done_testing;
