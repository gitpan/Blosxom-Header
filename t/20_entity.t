use strict;
use warnings;
use Blosxom::Header::Entity;
use Test::More tests => 19;
use Test::Warn;
use Test::Exception;

my $class = 'Blosxom::Header::Entity';

ok $class->isa( 'Blosxom::Header::Adapter' );

can_ok $class, qw(
    new clear delete exists get set is_empty
    dump as_hashref
    each flatten
    content_type type charset
    last_modified date
    status 
    UNTIE DESTROY
);

# initialize
my %header;
my $header = $class->new( \%header );

# exists()
%header = ( -foo => 'bar' );
ok $header->exists('Foo'), 'should return true';
ok !$header->exists('Bar'), 'should return false';

# get()
%header = ( -foo => 'bar', -bar => 'baz' );
is $header->get('Foo'), 'bar';
is $header->get('Baz'), undef;
is $header->get('Foo', 'Bar'), 'baz';
is_deeply [ $header->get('Foo', 'Bar') ], [ 'bar', 'baz' ];

# clear()
%header = ( -foo => 'bar' );
$header->clear;
is_deeply \%header, { -type => q{} }, 'should be empty';

subtest 'set()' => sub {
    my $expected = qr{^Odd number of elements passed to set\(\)};
    throws_ok { $header->set('Foo') } $expected;

    %header = ();

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
    %header = ();
    is $header->delete('Foo'), undef;

    %header = ( -foo => 'bar' );
    is $header->delete('Foo'), 'bar';
    is_deeply \%header, {};

    %header = (
        -foo => 'bar',
        -bar => 'baz',
    );

    is_deeply [ $header->delete('Foo', 'Bar') ], [ 'bar', 'baz' ];
    is_deeply \%header, {};

    %header = (
        -foo => 'bar',
        -bar => 'baz',
    );

    ok $header->delete('Foo', 'Bar') eq 'baz';
    is_deeply \%header, {};
};

subtest 'each()' => sub {
    my $expected = qr{^Must provide a code reference to each\(\)};
    throws_ok { $header->each } $expected;

    %header = (
        -status         => '304 Not Modified',
        -content_length => 12345,
    );

    my @got;
    $header->each(sub {
        my ( $field, $value ) = @_;
        push @got, $field, $value;
    });

    my @expected = (
        'Status',         '304 Not Modified',
        'Content-length', '12345',
        'Content-Type',   'text/html; charset=ISO-8859-1',
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
    %header = (
        -status         => '304 Not Modified',
        -content_length => 12345,
    );

    my @got = $header->flatten;

    my @expected = (
        'Status',         '304 Not Modified',
        'Content-length', '12345',
        'Content-Type',   'text/html; charset=ISO-8859-1',
    );

    is_deeply \@got, \@expected;
};

subtest 'as_hashref()' => sub {
    my $got = $header->as_hashref;
    ok ref $got eq 'HASH';
    ok tied %{ $got } eq $header;

    %header = ();
    $header->{Foo} = 'bar';
    is_deeply \%header, { -foo => 'bar' }, 'store';

    %header = ( -foo => 'bar' );
    is $header->{Foo}, 'bar', 'fetch';
    is $header->{Bar}, undef;

    %header = ( -foo => 'bar' );
    ok exists $header->{Foo}, 'exists';
    ok !exists $header->{Bar};

    %header = ( -foo => 'bar' );
    is delete $header->{Foo}, 'bar';
    is_deeply \%header, {}, 'delete';

    %header = ( -foo => 'bar' );
    %{ $header } = ();
    is_deeply \%header, { -type => q{} }, 'clear';
};

subtest 'status()' => sub {
    %header = ();
    is $header->status, undef;

    $header->status( 304 );
    is $header{-status}, '304 Not Modified';
    is $header->status, '304';

    my $expected = q{Unknown status code '999' passed to status()};
    warning_is { $header->status( 999 ) } $expected;
};

subtest 'target()' => sub {
    %header = ();
    is $header->target, undef;
    $header->target( 'ResultsWindow' );
    is $header->target, 'ResultsWindow';
    is_deeply \%header, { -target => 'ResultsWindow' };
};

subtest 'dump()' => sub {
    %header = ( -type => 'text/plain' );

    my $got = eval $header->dump;

    my %expected = (
        adapter => {
            'Content-Type' => 'text/plain; charset=ISO-8859-1',
        },
        adaptee => {
            '-type' => 'text/plain',
        },
    );

    is_deeply $got, \%expected;
};

subtest 'DESTROY()' => sub {
    $header->DESTROY;
    ok !$header->as_hashref;
    ok !$header->header;
};
