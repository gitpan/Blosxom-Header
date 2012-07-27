use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header qw(
    header_set header_get header_exists header_delete
    header_iter
);

{
    package blosxom;
    our $header = {};
}

my $header = Blosxom::Header->new;

# STORE
cmpthese(100000, {
    overload => sub { $header->{Foo} = 'bar'       },
    method   => sub { $header->set( Foo => 'bar' ) },
    function => sub { header_set( Foo => 'bar' )   },
});

# FETCH
cmpthese(100000, {
    overload => sub { my $value = $header->{Foo}        },
    method   => sub { my $value = $header->get( 'Foo' ) },
    function => sub { my $value = header_get( 'Foo' )   },
});

# EXISTS
cmpthese(100000, {
    overload => sub { my $bool = exists $header->{Foo}    },
    method   => sub { my $bool = $header->exists( 'Foo' ) },
    function => sub { my $bool = header_exists( 'Foo' )   },
});

# DELETE
cmpthese(100000, {
    overload => sub {
        $blosxom::header->{-foo} = 'bar';
        my $deleted = delete $header->{Foo}
    },
    method => sub {
        $blosxom::header->{-foo} = 'bar';
        my $deleted = $header->delete( 'Foo' );
    },
    function => sub {
        $blosxom::header->{-foo} = 'bar';
        my $deleted = header_delete( 'Foo' );
    },
});

$header->set(
    Foo => 'bar',
    Bar => 'baz',
    Baz => 'qux',
);

cmpthese(10000, {
    method => sub {
        my @headers;
        $header->each( sub { push @headers, @_ } );
    },
    function => sub {
        my @headers;
        header_iter( sub { push @headers, @_ } );
    },
});
