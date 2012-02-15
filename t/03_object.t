use strict;
use Test::More;
use Blosxom::Header;

{
    my $header_ref = { foo => 'bar' };
    my $h = Blosxom::Header->new( $header_ref );
    isa_ok $h, 'Blosxom::Header::Object';
    can_ok $h, qw( new get set has remove );

    is $h->get('foo'), 'bar';
    ok $h->has('foo');

    $h->set( 'bar' => 'baz' );
    is_deeply $header_ref, { foo => 'bar', bar => 'baz' };

    $h->remove('foo');
    is_deeply $header_ref, { bar => 'baz' };
}

done_testing;
