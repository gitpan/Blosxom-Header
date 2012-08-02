use strict;
use Blosxom::Header;
use Test::More tests => 14;
use Test::Warn;
use Test::Exception;

{
    package blosxom;
    our $header;
}

{
    my $expected = qr{^\$blosxom::header hasn't been initialized yet};
    throws_ok { Blosxom::Header->new } $expected;
}

# initialize
my %header;
$blosxom::header = \%header;

my $header = Blosxom::Header->new;
ok $header->isa( 'Blosxom::Header' );
can_ok $header, qw(
    clear delete exists field_names get set
    as_hashref is_empty flatten
    content_type type charset
    p3p_tags push_p3p_tags 
    last_modified date expires
    attachment charset nph status target
);

# exists()
%header = ( -foo => 'bar' );
ok $header->exists( 'Foo' ), 'should return true';
ok !$header->exists( 'Bar' ), 'should return false';

# get()
%header = ( -foo => 'bar', -bar => 'baz' );
my @got = $header->get( 'Foo', 'Bar' );
my @expected = qw( bar baz );
is_deeply \@got, \@expected;

# clear()
%header = ( -foo => 'bar' );
$header->clear;
is_deeply \%header, { -type => q{} }, 'should be empty';

subtest 'set()' => sub {
    %header = ();

    my $expected = 'Odd number of elements passed to set()';
    warning_is { $header->set( 'Foo' ) } $expected;

    $header->set(
        Foo => 'bar',
        Bar => 'baz',
        Baz => 'qux',
    );

    my %expected = (
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    );

    is_deeply \%header, \%expected, 'set() multiple elements';
};

subtest 'delete()' => sub {
    %header = (
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    );
    my @deleted = $header->delete( qw/foo bar/ );
    is_deeply \@deleted, [ 'bar', 'baz' ], 'delete() multiple elements';
    is_deeply \%header, { -baz => 'qux' };

    %header = (
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    );
    is $header->delete(qw/foo bar baz/), 'qux';
    is_deeply \%header, {};
};

subtest 'expires()' => sub {
    %header = ();
    is $header->expires, undef;

    my $now = 1341637509;
    $header->expires( $now );
    is $header->expires, $now, 'get expires()';
    is $header{-expires}, $now;

    $now++;
    $header->expires( 'Sat, 07 Jul 2012 05:05:10 GMT' );
    is $header->expires, $now, 'get expires()';
    is $header{-expires}, 'Sat, 07 Jul 2012 05:05:10 GMT';
};

subtest 'each()' => sub {
    %header = ( -foo => 'bar' );
    my @got;
    $header->each( sub { push @got, @_ } );
    my @expected = (
        'Foo'          => 'bar',
        'Content-Type' => 'text/html; charset=ISO-8859-1',
    );
    is_deeply \@got, \@expected;
};

subtest 'is_empty()' => sub {
    %header = ();
    ok !$header->is_empty;
    %header = ( -type => q{} );
    ok $header->is_empty;
};

subtest 'flatten()' => sub {
    %header = ();
    my @got = $header->flatten;
    my @expected = ( 'Content-Type', 'text/html; charset=ISO-8859-1' );
    is_deeply \@got, \@expected;

    %header = ( -p3p => [ 'foo', 'bar' ] );
    @got = $header->flatten;
    @expected = (
        'P3P',          'policyref="/w3c/p3p.xml", CP="foo bar"',
        'Content-Type', 'text/html; charset=ISO-8859-1',
    );
    is_deeply \@got, \@expected;
};

subtest 'as_hashref()' => sub {
    my $got = $header->as_hashref;
    ok ref $got eq 'HASH';

    ok my $tied = tied( %{ $got } );
    ok $tied eq $header;

    %header = ();
    $header->{Foo} = 'bar';
    is_deeply \%header, { -foo => 'bar' }, 'overload';

    untie %{ $header->as_hashref };
    ok !$header->as_hashref, 'untie';
};

