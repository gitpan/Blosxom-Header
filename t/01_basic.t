use strict;
use Test::More;
use Blosxom::Header;

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new( $header_ref );
    isa_ok $h, 'Blosxom::Header';
    can_ok $h, qw(new get remove exists set);
}

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new( $header_ref );
    $h->set( bar => 'baz' );
    is_deeply $header_ref, { '-foo' => 'bar', 'bar' => 'baz' };
}

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new( $header_ref );
    $h->set( -foo => q{} );
    is_deeply $header_ref, { '-foo' => q{} }, 'set empty string';
}

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($header_ref);
    $h->set( -foo => 'baz' );
    is_deeply $header_ref, { '-foo' => 'baz' }, 'set overwrite';
}

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($header_ref);
    $h->set( Foo => 'baz' );
    is_deeply $header_ref, { '-foo' => 'baz' }, 'set case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($header_ref);
    is $h->get('-foo'), 'bar';
}

{
    my $header_ref = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($header_ref);
    is $h->get('Foo'), 'bar', 'get case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($header_ref);
    $h->remove('-foo');
    is_deeply $header_ref, { '-bar' => 'baz' };
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($header_ref);
    $h->remove('Foo');
    is_deeply $header_ref, { '-bar' => 'baz' }, 'remove case-sensitive';
}

{
    my $header_ref = { '-foo' => 'bar', 'foo' => 'baz', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($header_ref);
    $h->remove('Foo');
    is_deeply $header_ref, { '-bar' => 'baz' }, 'remove multiple values';
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($header_ref);
    ok $h->exists('-foo');
    ok !$h->exists('baz');
}

{
    my $header_ref = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($header_ref);
    ok $h->exists('Foo'), 'exists case-sensitive';
}

done_testing;
