use strict;
use Test::More;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({});
    $header->push( '-cookie', 'foo' );
    is_deeply $header->{header}, { cookie => 'foo' }, 'push cookie';
}

{
    my $header = Blosxom::Header->new({});
    $header->push( '-p3p', 'foo' );
    is_deeply $header->{header}, { p3p => 'foo' }, 'push p3p';
}

{
    my $header = Blosxom::Header->new({});
    $header->push( 'Set-Cookie', 'foo' );
    my $expected = { cookie => 'foo' };
    is_deeply $header->{header}, $expected, 'push, not case-sensitive';
}

{
    my $header = Blosxom::Header->new({ cookie => 'foo' });
    $header->push( 'cookie', 'bar' );
    my $expected = { cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, 'push';
}

{
    my $header = Blosxom::Header->new({ cookie => [ 'foo' ] });
    $header->push( 'cookie', 'bar' );
    my $expected = { cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, 'push';
}


{
    my $header = Blosxom::Header->new({
        cookie  => 'foo',
        -cookie => 'bar',
    });
    eval { $header->push( 'cookie', 'baz' ) };
    like $@, qr{^Multiple elements specify the cookie header};
}

{
    my $header = Blosxom::Header->new({});
    eval { $header->push( 'foo', 'bar' ) };
    like $@, qr{^Can't push the foo header};
}

done_testing;
