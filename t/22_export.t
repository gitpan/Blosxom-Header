use strict;
use Test::More tests => 6;

BEGIN {
    my @methods = qw(
        header_get    header_set  header_exists
        header_delete push_cookie push_p3p
    );
    use_ok 'Blosxom::Header', ( '$Header', @methods );
    can_ok __PACKAGE__, @methods;
}

ok( $Header );
ok( Blosxom::Header->has_instance );
is $Header, Blosxom::Header->instance;

{
    package blosxom;
    our $header = {};
}

subtest 'functions' => sub {
    is header_get( 'Content-Type' ), 'text/html; charset=ISO-8859-1';
    is header_get( 'Status' ), undef;

    ok header_exists( 'Content-Type' );
    ok !header_exists( 'Status' );

    header_set( Status => '304 Not Modified' );
    is_deeply $blosxom::header, { -status => '304 Not Modified' };

    is header_delete( 'Status' ), '304 Not Modified';
    is_deeply $blosxom::header, {};

    is push_p3p( 'CAO' ), 1;
    is_deeply $blosxom::header, { -p3p => 'CAO' };

    is push_p3p( 'DSP' ), 2;
    is_deeply $blosxom::header, { -p3p => [qw/CAO DSP/] };

    is push_p3p( 'LAW' ), 3;
    is_deeply $blosxom::header, { -p3p => [qw/CAO DSP LAW/] };
};
