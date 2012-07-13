use strict;
use Blosxom::Header::Adapter;
use Test::More tests => 16;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header::Adapter', \%adaptee;
isa_ok $adapter, 'Blosxom::Header::Adapter';
can_ok $adapter, qw(
    FETCH STORE DELETE EXISTS CLEAR FIRSTKEY NEXTKEY SCALAR
    attachment nph normalize denormalize has_date_header
);

# SCALAR
%adaptee = ();
ok %adapter;
%adaptee = ( -type => q{} );
ok !%adapter;

# CLEAR
%adaptee = ();
%adapter = ();
is_deeply \%adaptee, { -type => q{} };

# EXISTS
%adaptee = ( -foo => 'bar', -bar => q{} );
ok exists $adapter{Foo};
ok !exists $adapter{Bar};
ok !exists $adapter{Baz};

# DELETE
%adaptee = ( -foo => 'bar', -bar => 'baz' );
is delete $adapter{Foo}, 'bar';
is_deeply \%adaptee, { -bar => 'baz' };

# FETCH
%adaptee = ( -foo => 'bar' );
is $adapter{Foo}, 'bar';
is $adapter{Bar}, undef;

# STORE
%adaptee = ();
$adapter{Foo} = 'bar';
is_deeply \%adaptee, { -foo => 'bar' };

# nph()
%adaptee = ();
ok !$adapter->nph;
$adapter->nph( 1 );
ok $adapter->nph;
is $adaptee{-nph}, 1;
