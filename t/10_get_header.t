use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header qw(get_header);

{
    my $header_ref = { '-foo' => 'bar' };
    is get_header( $header_ref, '-foo' ), 'bar';
    is get_header( $header_ref, '-bar' ), undef, 'get undef';
    is get_header( $header_ref, 'Foo'  ), 'bar', 'get case-sensitive';
}

{
    my $header_ref = { '-cookie' => [ 'foo', 'bar' ] };
    is get_header( $header_ref, 'Set-Cookie' ), 'foo', 'get scalar context';

    my @values = get_header( $header_ref, 'Set-Cookie' );
    is_deeply \@values, [ 'foo', 'bar' ], 'get list context';
}

{
    my $header_ref = { '-p3p' => [ 'foo', 'bar' ] };
    is get_header( $header_ref, 'p3p' ), 'foo', 'get scalar context';

    my @values = get_header( $header_ref, 'p3p' );
    is_deeply \@values, [ 'foo', 'bar' ], 'get list context';
}

{
    my $header_ref = { 'foo' => [ 'bar', 'baz' ] };
    warning_is { get_header( $header_ref, 'foo' ) }
        'The foo header must be scalar.';
}

{
    my $header_ref = { '-foo' => 'bar', 'foo' => 'baz' };
    warning_is { get_header( $header_ref, 'foo' ) }
        'Multiple elements specify the foo header.';
}


done_testing;
