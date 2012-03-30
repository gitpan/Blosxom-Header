use strict;
use Blosxom::Header;
use Test::More;

{
    my $header_ref = { foo => 'bar' };
    my $h = Blosxom::Header->new( $header_ref );

    is $h->get('foo'), 'bar';
    ok $h->exists('foo');

    $h->set( bar => 'baz' );
    is_deeply $header_ref, { foo => 'bar', bar => 'baz' };

    $h->delete('foo');
    is_deeply $header_ref, { bar => 'baz' };
}

{
    my $header_ref = {};
    my $h = Blosxom::Header->new( $header_ref );

    $h->push( 'Set-Cookie', 'foo' );
    is_deeply $header_ref, { cookie => [ 'foo' ] };
}

{
    my $header_ref = { cookie => [ 'foo', 'bar' ] };
    my $h = Blosxom::Header->new( $header_ref );
    is $h->get( 'Set-Cookie' ), 'foo';

    my @values = $h->get( 'Set-Cookie' );
    is_deeply \@values, [ 'foo', 'bar' ];
}

done_testing;
