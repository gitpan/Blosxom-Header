use strict;
use Blosxom::Header;
use Test::More tests => 17;
use Test::Warn;

{
    package blosxom;
    our $header;
}

my $header = Blosxom::Header->instance;
isa_ok $header, 'Blosxom::Header';
can_ok $header, qw(
    is_initialized clear delete exists field_names get set
    push_cookie push_p3p
    attachment charset cookie expires nph p3p status target type
);

our $Header;
*Header = \$blosxom::header;

subtest 'is_initialized()' => sub {
    undef $Header;
    ok !$header->is_initialized, 'should return false';

    $Header = {};
    ok $header->is_initialized, 'should return true';
};

subtest 'exists()' => sub {
    $Header = { -foo => 'bar' };
    ok $header->exists( 'Foo' ), 'should return true';
    ok !$header->exists( 'Bar' ), 'should return false';
};

subtest 'get()' => sub {
    $Header = { -foo => 'bar', -bar => 'baz' };
    my @got = $header->get( 'Foo', 'Bar' );
    my @expected = qw( bar baz );
    is_deeply \@got, \@expected;
};

subtest 'clear()' => sub {
    $Header = { -foo => 'bar' };
    $header->clear;
    is_deeply $Header, { -type => q{} }, 'should be empty';
};

subtest 'set()' => sub {
    $Header = {};

    warning_is { $header->set( 'Foo' ) }
        'Odd number of elements in hash assignment';

    warning_is { $header->set } 'Useless use of set() with no values';

    $header->set( Foo => 'baz' );
    is $Header->{-foo}, 'baz', 'set(), not case-sesitive';

    $header->set(
        Bar => 'baz',
        Baz => 'qux',
    );

    my %expected = (
        -foo => 'baz',
        -bar => 'baz',
        -baz => 'qux',
    );

    is_deeply $Header, \%expected, 'set() multiple elements';
};

subtest 'delete()' => sub {
    $Header = {
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    };

    warning_is { $header->delete } 'Useless use of delete() with no values';

    my @deleted = $header->delete( qw/foo bar/ );
    is_deeply \@deleted, [ 'bar', 'baz' ], 'delete() multiple elements';
    is_deeply $Header, { -baz => 'qux' };
};

subtest 'expires()' => sub {
    $Header = {};
    is $header->expires, undef;
    is $header->expires( 'now' ), 'now', 'set expires()';
    is $header->expires, 'now', 'get expires()';
    is $Header->{-expires}, 'now';
};

subtest 'push_cookie()' => sub {
    $Header = {};

    warning_is { $header->push_cookie }
        'Useless use of _push() with no values';

    is $header->push_cookie( 'foo' ), 1, '_push()';
    is $Header->{-cookie}, 'foo';

    is $header->push_cookie( 'bar' ), 2, '_push()';
    is_deeply $Header->{-cookie}, [ 'foo', 'bar' ];

    is $header->push_cookie( 'baz' ), 3, '_push()';
    is_deeply $Header->{-cookie}, [ 'foo', 'bar', 'baz' ];
};

subtest 'cookie()' => sub {
    $Header = {};

    is $header->cookie, undef;
    is $header->cookie( 'foo' ), 'foo', 'set cookie()';
    is $header->cookie,          'foo', 'get cookie()';
    is $Header->{-cookie}, 'foo';

    my @cookies = qw(foo bar baz);
    $header->cookie( @cookies );
    is_deeply $Header->{-cookie}, \@cookies, 'cookie() receives LIST';
};

subtest 'status()' => sub {
    $Header = {};

    is $header->status, undef;
    is $header->status( 304 ), '304';
    is $Header->{-status}, '304 Not Modified';
    is $header->status, '304';

    my $expected = 'Unknown status code "999" passed to status()';
    warning_is { $header->status( 999 ) } $expected;
};

subtest 'charset()' => sub {
    $Header = {};
    is $header->charset, 'ISO-8859-1';

    $Header = { -charset => q{} };
    is $header->charset, undef;

    $Header = { -charset => 'utf-8' };
    is $header->charset, 'UTF-8';

    $Header = { -type => q{}, -charset => 'utf-8' };
    is $header->charset, undef;

    $Header = { -type => 'text/html; charset=euc-jp' };
    is $header->charset, 'EUC-JP';

    $Header = { -type => 'text/html; charset=euc-jp', -charset => q{}  };
    is $header->charset, 'EUC-JP';

    $Header = { -type => 'text/html; charset=iso-8859-1; Foo=1' };
    is $header->charset, 'ISO-8859-1';

    $Header = { -type => 'text/html; charset="iso-8859-1"; Foo=1' };
    is $header->charset, 'ISO-8859-1';

    $Header = {
        -type    => 'text/html; charset=euc-jp',
        -charset => 'utf-8',
    };
    is $header->charset, 'EUC-JP';
};

subtest 'type()' => sub {
    $Header = {};
    is $header->type, 'text/html';
    my @got = $header->type;
    my @expected = ( 'text/html', 'charset=ISO-8859-1' );
    is_deeply \@got, \@expected;

    $Header = { -type => 'text/plain; charset=EUC-JP' };
    is $header->type, 'text/plain';
    @got = $header->type;
    @expected = ( 'text/plain', 'charset=EUC-JP' );
    is_deeply \@got, \@expected;

    $Header = { -type => 'text/plain; charset=EUC-JP; Foo=1' };
    is $header->type, 'text/plain';
    @got = $header->type;
    @expected = ( 'text/plain', 'charset=EUC-JP; Foo=1' );
    is_deeply \@got, \@expected;

    $Header = { -charset => 'utf-8' };
    is $header->type( 'text/plain; charset=EUC-JP' ), 'text/plain';
    is_deeply $Header, { -type => 'text/plain; charset=EUC-JP' };

    $Header = { -type => '   TEXT  / HTML   ', -charset => q{} };
    is $header->type, 'text/html';

    $Header = { -type => 'text/plain', -charset => 'utf-8' };
    @got = $header->type;
    @expected = ( 'text/plain', 'charset=utf-8' );
    is_deeply \@got, \@expected;

    $Header = { -type => 'text/plain; Foo=1', -charset => 'utf-8' };
    @got = $header->type;
    @expected = ( 'text/plain', 'Foo=1; charset=utf-8' );
    is_deeply \@got, \@expected;

    $Header = {
        -type    => 'text/plain; charset=euc-jp',
        -charset => 'utf-8',
    };
    @got = $header->type;
    @expected = ( 'text/plain', 'charset=euc-jp' );
    is_deeply \@got, \@expected;
};

subtest 'field_names()' => sub {
    $Header = { -foo => 'bar' };
    my @got = sort $header->field_names;
    my @expected = qw( Content-Type Foo );
    is_deeply \@got, \@expected;
};

subtest 'p3p()' => sub {
    $Header = {};
    my @got = $header->p3p( 'CAO DSP LAW CURa' );
    my @expected = qw( CAO DSP LAW CURa );
    is_deeply $Header, { -p3p => [qw/CAO DSP LAW CURa/] };
    is_deeply \@got, \@expected;

    $Header = {};
    @got = $header->p3p( qw/CAO DSP LAW CURa/ );
    @expected = qw( CAO DSP LAW CURa );
    is_deeply $Header, { -p3p => [qw/CAO DSP LAW CURa/] };
    is_deeply \@got, \@expected;

    $Header = { -p3p => [qw/CAO DSP LAW CURa/] };
    is $header->p3p, 'CAO';
    @got = $header->p3p;
    @expected = qw( CAO DSP LAW CURa );
    is_deeply \@got, \@expected;

    $Header = { -p3p => [ 'CAO DSP', 'LAW CURa' ] };
    is $header->p3p, 'CAO';
    @got = $header->p3p;
    @expected = qw( CAO DSP LAW CURa );
    is_deeply \@got, \@expected;

    $Header = { -p3p => 'CAO DSP LAW CURa' };
    is $header->p3p, 'CAO';
    @got = $header->p3p;
    @expected = qw( CAO DSP LAW CURa );
    is_deeply \@got, \@expected;
};

subtest 'cookie()' => sub {
    $Header = {};
    my @got = $header->cookie( 'foo', 'bar' );
    my @expected = qw( foo bar );
    is_deeply $Header, { -cookie => [qw/foo bar/] };
    is_deeply \@got, \@expected;

    $Header = { -cookie => [qw/foo bar/] };
    @got = $header->cookie;
    @expected = qw( foo bar );
    is_deeply \@got, \@expected;
};
