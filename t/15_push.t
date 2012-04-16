use strict;
use Test::More;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({});
    $header->push( -foo => 'bar' );
    is_deeply $header->{header}, { -foo => 'bar' }, 'push';
}

{
    my $header = Blosxom::Header->new({});
    $header->push( Foo => 'bar' );
    is_deeply $header->{header}, { -foo => 'bar' }, 'push, not case-sensitive';
}

{
    my $header = Blosxom::Header->new({ -cookie => 'foo' });
    $header->push( 'Set-Cookie' => 'bar' );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, 'push';
}

{
    my @cookies = ( 'foo' );
    my $header_ref = { -cookie => \@cookies };
    my $header = Blosxom::Header->new( $header_ref );
    $header->push( 'Set-Cookie' => 'bar' );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header_ref, $expected, 'push';
    is $header_ref->{-cookie}, \@cookies, 'push';
}

done_testing;
