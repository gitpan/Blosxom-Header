use strict;
use Test::More;
use Blosxom::Header;

{
    my $header_ref = { foo => 'bar' };
    my $h = Blosxom::Header->new( $header_ref );
    isa_ok $h, 'Blosxom::Header::Prototype';
    can_ok $h, qw( get set exists delete );

    is $h->get('foo'), 'bar';
    ok $h->exists('foo');

    $h->set( 'bar' => 'baz' );
    is_deeply $header_ref, { foo => 'bar', bar => 'baz' };

    $h->delete('foo');
    is_deeply $header_ref, { bar => 'baz' };
}

done_testing;
