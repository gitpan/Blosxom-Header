use strict;
use Test::Exception;
use Test::More tests => 12;

BEGIN {
    my @functions = qw(
        header_get    header_set  header_exists
        header_delete push_p3p header_iter
    );
    use_ok 'Blosxom::Header', @functions;
    can_ok __PACKAGE__, @functions;
}

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

is push_p3p( 'CAO' ), 1;
is $header{-p3p}, 'CAO';

my @got;
header_iter sub {
    my $field = shift;
    push @got, $field;
};

is_deeply \@got, [qw/P3P Content-Type/];

