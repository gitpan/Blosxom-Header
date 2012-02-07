use strict;
use Test::More;
use Blosxom::Header;

{
    my $h = Blosxom::Header->new({});
    isa_ok $h, 'Blosxom::Header';
    can_ok $h, qw(new get remove exists set);
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    $h->set(-foo => 'baz');
    is_deeply $headers, { '-foo' => 'baz' };
}


{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    $h->set(-foo => q{});
    is_deeply $headers, { '-foo' => q{} }, 'set empty string';
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    $h->set(bar => 'baz');
    is_deeply $headers, { '-foo' => 'bar', 'bar' => 'baz' };
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    $h->set(Foo => 'baz');
    is_deeply $headers, { '-foo' => 'baz' }, 'set case-sensitive';
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    is $h->get('-foo'), 'bar';
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    is $h->get('Foo'), 'bar', 'get case-sensitive';
}

{
    # edge case
    my $headers = { '-foo' => 'bar', 'foo' => 'baz', 'bar' => 'foo'  };
    my $h = Blosxom::Header->new($headers);
    like $h->get('foo'), qr/^(bar|baz)$/, 'get scalar context'; 

    my @values = sort $h->get('foo');
    is_deeply \@values, [qw(bar baz)], 'get list context';
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    $h->remove('-foo');
    is_deeply $headers, { '-bar' => 'baz' };
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    $h->remove('Foo');
    is_deeply $headers, { '-bar' => 'baz' }, 'remove case-sensitive';
}

{
    my $headers = { '-foo' => 'bar', 'foo' => 'baz', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    $h->remove('Foo');
    is_deeply $headers, { '-bar' => 'baz' }, 'remove multiple values';
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    ok $h->exists('-foo');
    ok !$h->exists('baz');
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    ok $h->exists('Foo'), 'exists case-sensitive';
}

done_testing;
