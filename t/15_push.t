use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({});
    $header->push( -foo => 'bar' );
    is_deeply $header->{header}, { -foo => 'bar' }, 'push';
}

{
    my $header = Blosxom::Header->new({});
    $header->push( -cookie => qw/foo bar/ );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, 'push multiple values';
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
    my $header = Blosxom::Header->new({ -cookie => \@cookies });
    $header->push( 'Set-Cookie' => 'bar' );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, 'push';
    is $header->{header}->{-cookie}, \@cookies, 'push';
}

{
    my $header = Blosxom::Header->new({});
    warning_is { $header->push( 'Foo' ) } 'Useless use of push with no values';
}

done_testing;
