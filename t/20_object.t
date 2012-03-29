use strict;
use Blosxom::Header;
use Test::More;

{
    my $header_ref = {};
    my $h = Blosxom::Header->new( $header_ref );
    isa_ok $h, 'Blosxom::Header::Object';
    #can_ok $h, qw( new header get set push exists delete DESTROY );
    can_ok $h, qw( new header get set push_cookie exists delete DESTROY );
    is $h->header, $header_ref;
}

{
    eval { Blosxom::Header->new };
    like $@, qr{^Must pass a reference to hash.};
}

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

    #$h->push( 'Set-Cookie', 'foo' );
    $h->push_cookie( 'foo' );
    is_deeply $header_ref, { cookie => [ 'foo' ] };

    #$h->push( 'P3P', 'foo' );
    #is_deeply $header_ref, { cookie => [ 'foo' ], p3p => [ 'foo' ] };
}

done_testing;
