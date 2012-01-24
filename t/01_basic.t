use strict;
use Test::More;
use Blosxom::Header;

{
    my $headers = { '-foo' => 'bar' };

    my $h = Blosxom::Header->new($headers);

    isa_ok $h, 'Blosxom::Header';
    can_ok $h, qw(get set remove exists);
    is_deeply $h, { headers => $headers };
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    $h->set(foo => 'baz');
    is_deeply $headers, { '-foo' => 'baz' };
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    $h->set(bar => 'baz');
    is_deeply $headers, { '-foo' => 'bar', '-bar' => 'baz' };
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
    is $h->get('foo'), 'bar';
}

{
    my $headers = { '-foo' => 'bar' };
    my $h = Blosxom::Header->new($headers);
    is $h->get('Foo'), 'bar', 'get case-sensitive';
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    $h->remove('foo');
    is_deeply $headers, { '-bar' => 'baz' };
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    $h->remove('Foo');
    is_deeply $headers, { '-bar' => 'baz' }, 'remove case-sensitive';
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    is $h->exists('foo'), 1;
}

{
    my $headers = { '-foo' => 'bar', '-bar' => 'baz' };
    my $h = Blosxom::Header->new($headers);
    is $h->exists('Foo'), 1, 'exists case-sensitive';
}

done_testing;
