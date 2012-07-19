use strict;
use Test::More tests => 16;

BEGIN {
    my @functions = qw(
        header_get    header_set  header_exists
        header_delete push_cookie push_p3p each_header
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

# OBSOLETE
is push_cookie( 'foo' ), 1;
is $header{-cookie}, 'foo';

my @field_names;
each_header sub {
    my $field = shift;
    push @field_names, $field;
};
is_deeply [ sort @field_names ], [ qw/Content-Type Date P3P Set-Cookie/ ];

%header = ();
is each_header(), 'Content-Type';
is each_header(), undef;
