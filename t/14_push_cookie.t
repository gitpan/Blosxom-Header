use strict;
use Test::More;
use Blosxom::Header qw(push_cookie);

{
    my $header_ref = {};
    push_cookie( $header_ref, 'foo' );
    is_deeply $header_ref, { cookie => [ 'foo' ] };
}

{
    my $header_ref = { cookie => [ 'foo' ] };
    push_cookie( $header_ref, 'bar' );
    is_deeply $header_ref, { cookie => [ 'foo', 'bar' ] };
}

{
    my $header_ref = { cookie => 'foo' };
    push_cookie( $header_ref, 'bar' );
    is_deeply $header_ref, { cookie => [ 'foo', 'bar' ] };
}

done_testing;
