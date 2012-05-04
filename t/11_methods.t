use strict;
use Blosxom::Header;
use Test::More;
use Test::Warn;

{
    package blosxom;
    our $header;
}

eval { Blosxom::Header->instance };
like $@, qr{^\$blosxom::header hasn't been initialized yet};

# initialize
$blosxom::header = { -cookie => ['foo', 'bar'] };

my $header = Blosxom::Header->instance;
isa_ok $header, 'Blosxom::Header';

can_ok $header, qw(
    exists clear delete get set push_cookie push_p3p
    attachment charset cookie expires nph p3p status target type
);

warning_is { $header->get( 'cookie' ) }
    'Useless use of get() in void context';

is $header->get( 'cookie' ), 'foo', 'get() in scalar context';

{
    my @got = $header->get( 'cookie' );
    my @expected = qw/foo bar/;
    is_deeply \@got, \@expected, 'get() in list context';
}

warning_is { $header->push_p3p } 'Useless use of _push() with no values';

is $header->push_p3p( 'foo' ), 1, 'push()';
is $blosxom::header->{-p3p}, 'foo';

is $header->push_p3p( 'bar' ), 2, 'push()';
is_deeply $blosxom::header->{-p3p}, ['foo', 'bar'];

is $header->push_p3p( 'baz' ), 3, 'push()';
is_deeply $blosxom::header->{-p3p}, ['foo', 'bar', 'baz'];

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
is_deeply $blosxom::header->{-expires}, 'now';

done_testing;
