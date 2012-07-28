use strict;
use Blosxom::Header;
use CGI::Cookie;
use Test::More tests => 10;

my %header;

{
    package blosxom;
    our $header = \%header;
}

my $header = Blosxom::Header->new;

# set_cookie()

%header = ();
$header->set_cookie( foo => 'bar' );
my $got = $header{-cookie};
isa_ok $got, 'CGI::Cookie';
is $got->value, 'bar';

%header = ();
$header->set_cookie( foo => { value => 'bar' } );
$got = $header{-cookie};
isa_ok $got, 'CGI::Cookie';
is $got->value, 'bar';

my $cookie = CGI::Cookie->new(
    -name  => 'foo',
    -value => 'bar',
);

%header = ( -cookie => $cookie );
$header->set_cookie( foo => 'baz' );
$got = $header{-cookie};
isa_ok $got, 'CGI::Cookie';
is $got->value, 'baz';

$cookie = CGI::Cookie->new(
    -name  => 'foo',
    -value => 'bar',
);

%header = ( -cookie => $cookie );
$header->set_cookie( foo => { value => 'baz' } );
$got = $header{-cookie};
isa_ok $got, 'CGI::Cookie';
is $got->value, 'baz';

# get_cookie()

my $cookie1 = CGI::Cookie->new(
    -name  => 'foo',
    -value => 'bar',
);

my $cookie2 = CGI::Cookie->new(
    -name  => 'bar',
    -value => 'baz',
);

%header = ( -cookie => $cookie1 );
is $header->get_cookie( 'foo' ), $cookie1;

%header = ( -cookie => [ $cookie1, $cookie2 ] );
is $header->get_cookie( 'bar' ), $cookie2;
