use strict;
use Blosxom::Header;
use Test::More tests => 12;
use Test::Warn;

{
    package blosxom;
    our $header;
}

my $header = Blosxom::Header->instance;
isa_ok $header, 'Blosxom::Header';
can_ok $header, qw(
    clear delete exists get set
    push_cookie push_p3p
    attachment charset cookie expires nph p3p status target type
    is_initialized
);

subtest 'is_initialized()' => sub {
    ok !$header->is_initialized, 'should return false';
    local $blosxom::header = {};
    ok $header->is_initialized, 'should return true';
};

subtest 'exists()' => sub {
    local $blosxom::header = { -foo => 'bar' };
    ok $header->exists( 'Foo' ), 'should return true';
    ok !$header->exists( 'Bar' ), 'should return false';
};

subtest 'get()' => sub {
    local $blosxom::header = { -foo => [ 'bar', 'baz' ] };
    is $header->get( 'Foo' ), 'bar', 'in scalar context';
    my @got = $header->get( 'Foo' );
    my @expected = qw( bar baz );
    is_deeply \@got, \@expected, 'in list context';
};

subtest 'clear()' => sub {
    local $blosxom::header = { -foo => 'bar' };
    $header->clear;
    is_deeply $blosxom::header, {}, 'should be empty';
};

subtest 'set()' => sub {
    local $blosxom::header = {};

    warning_is { $header->set( 'Foo' ) }
        'Odd number of elements in hash assignment';

    warning_is { $header->set } 'Useless use of set() with no values';

    $header->set( Foo => 'baz' );
    is $blosxom::header->{-foo}, 'baz', 'set(), not case-sesitive';

    $header->set(
        Bar => 'baz',
        Baz => 'qux',
    );

    my %expected = (
        -foo => 'baz',
        -bar => 'baz',
        -baz => 'qux',
    );

    is_deeply $blosxom::header, \%expected, 'set() multiple elements';
};

subtest 'delete()' => sub {
    local $blosxom::header = {
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    };

    warning_is { $header->delete } 'Useless use of delete() with no values';

    my @deleted = $header->delete( qw/foo bar/ );
    is_deeply \@deleted, ['bar', 'baz'], 'delete() multiple elements';
    is_deeply $blosxom::header, { -baz => 'qux' };
};

subtest 'expires()' => sub {
    local $blosxom::header = {};
    is $header->expires, undef;
    is $header->expires( 'now' ), 'now', 'set expires()';
    is $header->expires, 'now', 'get expires()';
    is $blosxom::header->{-expires}, 'now';
};

subtest 'push_cookie()' => sub {
    local $blosxom::header = {};

    warning_is { $header->push_cookie }
        'Useless use of _push() with no values';

    is $header->push_cookie( 'foo' ), 1, '_push()';
    is $blosxom::header->{-cookie}, 'foo';

    is $header->push_cookie( 'bar' ), 2, '_push()';
    is_deeply $blosxom::header->{-cookie}, [ 'foo', 'bar' ];

    is $header->push_cookie( 'baz' ), 3, '_push()';
    is_deeply $blosxom::header->{-cookie}, [ 'foo', 'bar', 'baz' ];
};

subtest 'cookie()' => sub {
    local $blosxom::header = {};

    is $header->cookie, undef;
    is $header->cookie( 'foo' ), 'foo', 'set cookie()';
    is $header->cookie,          'foo', 'get cookie()';
    is $blosxom::header->{-cookie}, 'foo';

    my @cookies = qw(foo bar baz);
    $header->cookie( @cookies );
    is_deeply $blosxom::header->{-cookie}, \@cookies, 'cookie() receives LIST';
};

subtest 'status()' => sub {
    local $blosxom::header = {};

    is $header->status, undef;
    is $header->status( 304 ), '304';
    is $blosxom::header->{-status}, '304 Not Modified';
    is $header->status, '304';

    my $expected = 'Unknown status code "999" passed to status()';
    warning_is { $header->status( 999 ) } $expected;
};
