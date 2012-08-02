use strict;
use Test::Exception;
use Test::More tests => 10;

BEGIN {
    use_ok 'Blosxom::Header', qw(
        header_get    header_set  header_exists
        header_delete header_iter
    );
}

can_ok __PACKAGE__, qw(
    header_get    header_set  header_exists
    header_delete header_iter
);

my %header;

{
    package blosxom;
    our $header = \%header;
}

is header_get( 'Content-Type' ), 'text/html; charset=ISO-8859-1';
is header_get( 'Status' ), undef;

ok header_exists( 'Content-Type' );
ok !header_exists( 'Status' );

header_set( Status => '304 Not Modified' );
is_deeply \%header, { -status => '304 Not Modified' };

is header_delete( 'Status' ), '304 Not Modified';
is_deeply \%header, {};

my @got;
header_iter(sub { push @got, @_ });
is_deeply \@got, [ 'Content-Type', 'text/html; charset=ISO-8859-1' ];
