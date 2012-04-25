use strict;
use Test::More;
use Test::Warn;
use Blosxom::Header;

{
    my $header = Blosxom::Header->new({});
    $header->_push( -foo => 'bar' );
    is_deeply $header->{header}, { -foo => 'bar' }, '_push()';
}

{
    my $header = Blosxom::Header->new({});
    $header->_push( -cookie => qw/foo bar/ );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, '_push() multiple values';
}

{
    my $header = Blosxom::Header->new({});
    $header->_push( Foo => 'bar' );
    is_deeply $header->{header}, { -foo => 'bar' }, '_push(), not case-sensitive';
}

{
    my $header = Blosxom::Header->new({ -cookie => 'foo' });
    $header->_push( Set_Cookie => 'bar' );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, '_push() cookie';
}

{
    my @cookies = ( 'foo' );
    my $header = Blosxom::Header->new({ -cookie => \@cookies });
    $header->_push( Set_Cookie => 'bar' );
    my $expected = { -cookie => [ 'foo', 'bar' ] };
    is_deeply $header->{header}, $expected, '_push()';
    is $header->{header}->{-cookie}, \@cookies, '_push()';
}

{
    my $header = Blosxom::Header->new({});
    warning_is { $header->_push( 'Foo' ) } 'Useless use of _push() with no values';
}

done_testing;
