use strict;
use warnings;
use Blosxom::Header;
use Test::More tests => 16;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header', \%adaptee;
ok $adapter->isa( 'Blosxom::Header' );
can_ok $adapter, qw(
    FETCH STORE DELETE EXISTS CLEAR SCALAR
    _normalize _denormalize
    _date_header_is_fixed field_names
    push_p3p_tags p3p_tags expires nph attachment
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

subtest 'nph()' => sub {
    %adaptee = ();
    ok !$adapter->nph;
    $adapter->nph( 1 );
    ok $adapter->nph;
    is $adaptee{-nph}, 1;
};

subtest 'attachment()' => sub {
    %adaptee = ();
    is $adapter->attachment, undef;
    $adapter->attachment( 'genome.jpg' );
    is $adapter->attachment, 'genome.jpg';
    is_deeply \%adaptee, { -attachment => 'genome.jpg' };
};

subtest 'field_names()' => sub {
    %adaptee = ( -type => undef );
    my @got = $adapter->field_names;
    my @expected = ( 'Content-Type' );
    is_deeply \@got, \@expected;

    %adaptee = (
        -nph        => 'foo',
        -charset    => 'foo',
        -status     => 'foo',
        -target     => 'foo',
        -p3p        => 'foo',
        -cookie     => 'foo',
        -expires    => 'foo',
        -attachment => 'foo',
        -foo_bar    => 'foo',
        -foo        => q{},
        -bar        => q{},
        -baz        => q{},
        -qux        => q{},
    );

    @got = $adapter->field_names;

    @expected = qw(
        Status
        Window-Target
        P3P
        Set-Cookie
        Expires
        Date
        Content-Disposition
        Foo-bar
        Content-Type
    );

    is_deeply \@got, \@expected;
};
