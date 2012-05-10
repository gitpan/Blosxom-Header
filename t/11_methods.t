use strict;
use Blosxom::Header;
use Test::More;
use Test::Warn;

{
    package blosxom;
    our $header = { -cookie => ['foo', 'bar'] };
}

my $header = Blosxom::Header->instance;

isa_ok $header, 'Blosxom::Header';

can_ok $header, qw(
    exists clear delete get set
    attachment charset expires nph status target type
    cookie push_cookie
    p3p    push_p3p
);

ok $header->exists( 'cookie' ), 'exists()';

warning_is { $header->get( 'cookie' ) }
    'Useless use of get() in void context';

is $header->get( 'cookie' ), 'foo', 'get() in scalar context';

{
    my @got = $header->get( 'cookie' );
    my @expected = qw/foo bar/;
    is_deeply \@got, \@expected, 'get() in list context';
}

$header->clear;
is_deeply $blosxom::header, {}, 'clear()';

warning_is { $header->push_cookie } 'Useless use of _push() with no values';

is $header->push_cookie( 'foo' ), 1, '_push()';
is $blosxom::header->{-cookie}, 'foo';

is $header->push_cookie( 'bar' ), 2, '_push()';
is_deeply $blosxom::header->{-cookie}, ['foo', 'bar'];

is $header->push_cookie( 'baz' ), 3, '_push()';
is_deeply $blosxom::header->{-cookie}, ['foo', 'bar', 'baz'];

eval { $header->set( 'foo' ) };
like $@, qr{^Odd number of elements are passed to set()};

$header->set(
    -foo => 'bar',
    -bar => 'baz',
    -baz => 'qux',
);

{
    my @got = $header->delete( qw/foo bar/ );
    my @expected = qw/bar baz/;
    is_deeply \@got, \@expected, 'delete() multiple elements';
}

is $header->expires, undef;
is $header->expires( 'now' ), 'now';
is $header->expires, 'now';
is $blosxom::header->{-expires}, 'now';

done_testing;
