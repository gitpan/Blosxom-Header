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
my $tied_hash = $header->as_hashref;

# STORE
cmpthese(300000, {
    STORE     => sub { $header->STORE( Foo => 'bar' )  },
    tied_hash => sub { $tied_hash->{Foo} = 'bar'       },
    overload  => sub { $header->{Foo} = 'bar'          },
    method    => sub { $header->set( Foo => 'bar' )    },
    function  => sub { header_set( Foo => 'bar' )      },
});

# FETCH
cmpthese(300000, {
    FETCH     => sub { my $value = $header->FETCH( 'Foo' ) },
    tied_hash => sub { my $value = $tied_hash->{Foo}       },
    overload  => sub { my $value = $header->{Foo}          },
    method    => sub { my $value = $header->get( 'Foo' )   },
    function  => sub { my $value = header_get( 'Foo' )     },
});

# EXISTS
cmpthese(300000, {
    EXISTS    => sub { my $bool = $header->EXISTS( 'Foo' )  },
    tied_hash => sub { my $bool = exists $tied_hash->{Foo}  },
    overload  => sub { my $bool = exists $header->{Foo}     },
    method    => sub { my $bool = $header->exists( 'Foo' )  },
    function  => sub { my $bool = header_exists( 'Foo' )    },
});

# DELETE
cmpthese(300000, {
    DELETE => sub {
        $blosxom::header->{-foo} = 'bar';
        my $deleted = $header->DELETE( 'Foo' )
    },
    tied_hash => sub {
        $blosxom::header->{-foo} = 'bar';
        my $deleted = delete $tied_hash->{Foo}
    },
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

# CLEAR
cmpthese(300000, {
    CLEAR     => sub { $header->CLEAR       },
    tied_hash => sub { %{ $tied_hash } = () },
    overload  => sub { %{ $header } = ()    },
    method    => sub { $header->clear       },
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
