use strict;
use Test::More;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( -bar => 'baz' );
    is_deeply $header->{header}, { -foo => 'bar', -bar => 'baz' }, 'set';
}

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( -bar => q{} );
    my $expected = { -foo => 'bar', -bar => q{} };
    is_deeply $header->{header}, $expected, 'set empty string';
}

{
    my $header = Blosxom::Header->new({ -foo => 'bar' });
    $header->set( -foo => 'baz' );
    is_deeply $header->{header}, { -foo => 'baz' }, 'set overwrite';
}

{
    my $header = Blosxom::Header->new({});
    $header->set(
        -foo => 'bar',
        -bar => 'baz',
    );
    my $expected = { -foo => 'bar', -bar => 'baz' };
    is_deeply $header->{header}, $expected, 'set multiple elements';
}

{
    my $header = Blosxom::Header->new({});
    $header->set( Foo => 'bar' );
    is_deeply $header->{header}, { -foo => 'bar' }, 'set, not case-sensitive';
}

{
    my $header = Blosxom::Header->new({});
    $header->set( 'Set-Cookie' => [ 'foo', 'bar' ] );
    is_deeply $header->{header}, { -cookie => [ 'foo', 'bar' ] }, 'set cookie arrayref';
}

{
    my $header = Blosxom::Header->new({});
    $header->set( P3P => [ 'foo', 'bar' ] );
    is_deeply $header->{header}, { -p3p => [ 'foo', 'bar' ] }, 'set p3p arrayref';
}

{
    my $header = Blosxom::Header->new({});
    eval { $header->set( Foo => [ 'foo', 'bar' ] ) };
    like $@, qr{^The -foo header can't be an ARRAY reference};
}

done_testing;
