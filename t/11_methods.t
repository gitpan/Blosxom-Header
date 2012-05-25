use strict;
use Blosxom::Header;
use Test::More;
use Test::Warn;

{
    package blosxom;

    our $header = {
        -type   => 'text/html',
        -cookie => ['foo', 'bar'],
    };
}

my $header = Blosxom::Header->instance;
isa_ok $header, 'Blosxom::Header';
can_ok $header, qw(
    clear delete exists get push_cookie push_p3p set
    attachment charset cookie expires nph p3p status target type
);

ok $header->exists( 'type' ),    'exists() returns true';
ok !$header->exists( 'status' ), 'exists() returns false';

is $header->get( 'type' ),   'text/html', 'get()';
is $header->get( 'cookie' ), 'foo',       'get() in scalar context';
is_deeply [$header->get('cookie')], [qw/foo bar/], 'get() in list context';

$header->clear;
is_deeply $blosxom::header, {}, 'clear()';

# set()

warning_is { $header->set( 'foo' ) }
    'Odd number of elements in hash assignment';

warning_is { $header->set } 'Useless use of set() with no values';

$header->set( -foo => 'bar' );
is $blosxom::header->{-foo}, 'bar', 'set()';

$header->set( Foo => 'baz' );
is $blosxom::header->{-foo}, 'baz', 'set(), not case-sesitive';

$header->clear;

my %fields = (
    -foo => 'bar',
    -bar => 'baz',
    -baz => 'qux',
);

$header->set( %fields );
is_deeply $blosxom::header, \%fields, 'set() multiple elements';

# delete()

warning_is { $header->delete } 'Useless use of delete() with no values';

my @deleted = $header->delete( qw/foo bar/ );
is_deeply \@deleted, ['bar', 'baz'], 'delete() multiple elements';
is_deeply $blosxom::header, { -baz => 'qux' };

is $header->expires, undef;
is $header->expires( 'now' ), 'now', 'set expires()';
is $header->expires, 'now', 'get expires()';
is $blosxom::header->{-expires}, 'now';

$header->clear;

# Set-Cookie

warning_is { $header->push_cookie } 'Useless use of _push() with no values';

is $header->push_cookie( 'foo' ), 1, '_push()';
is $blosxom::header->{-cookie}, 'foo';

is $header->push_cookie( 'bar' ), 2, '_push()';
is_deeply $blosxom::header->{-cookie}, ['foo', 'bar'];

is $header->push_cookie( 'baz' ), 3, '_push()';
is_deeply $blosxom::header->{-cookie}, ['foo', 'bar', 'baz'];

$header->clear;

is $header->cookie, undef;
is $header->cookie( 'foo' ), 'foo', 'set cookie()';
is $header->cookie,          'foo', 'get cookie()';
is $blosxom::header->{-cookie}, 'foo';

my @cookies = qw(foo bar baz);
$header->cookie( @cookies );
is_deeply $blosxom::header->{-cookie}, \@cookies, 'cookie() receives LIST';

# P3P

is $header->p3p, undef;
is $header->p3p( 'foo' ), 'foo', 'set p3p()';
is $header->p3p, 'foo', 'get p3p()';
is $blosxom::header->{-p3p}, 'foo';

$header->clear;

my @p3p = qw(foo bar baz);
$header->p3p( @p3p );
is_deeply $blosxom::header->{-p3p}, \@p3p, 'p3p() receives LIST';

# Status

is $header->status, undef;
is $header->status(304), '304';
is $blosxom::header->{-status}, '304 Not Modified';
is $header->status, '304';

done_testing;
