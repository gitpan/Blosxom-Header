use strict;
use Test::More tests => 7;

BEGIN {
    my @methods = qw(
        header_get    header_set  header_exists
        header_delete header_push
    );
    use_ok 'Blosxom::Header', ( '$Header', @methods );
    can_ok __PACKAGE__, @methods;
}

ok( Blosxom::Header->has_instance );
ok( $Header );
is $Header, Blosxom::Header->has_instance;

my $h = Blosxom::Header->instance;
is $h, $Header;

{
    package blosxom;
    our $header;
}

subtest 'functions' => sub {
    $blosxom::header = {};

    is header_get( 'Content-Type' ), 'text/html; charset=ISO-8859-1';
    is header_get( 'Status' ), undef;

    ok header_exists( 'Content-Type' );
    ok !header_exists( 'Status' );

    header_set( Status => '304 Not Modified' );
    is_deeply $blosxom::header, { -status => '304 Not Modified' };

    is header_delete( 'Status' ), '304 Not Modified';
    is_deeply $blosxom::header, {};

    is header_push( P3P => 'CAO' ), 1;
    is_deeply $blosxom::header, { -p3p => 'CAO' };

    is header_push( P3P => 'DSP' ), 2;
    is_deeply $blosxom::header, { -p3p => [qw/CAO DSP/] };

    is header_push( P3P => 'LAW' ), 3;
    is_deeply $blosxom::header, { -p3p => [qw/CAO DSP LAW/] };
};
