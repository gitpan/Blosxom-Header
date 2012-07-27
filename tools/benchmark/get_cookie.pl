use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header;
use CGI::Cookie;

{
    package blosxom;
    our $header = {};
}

my $header = Blosxom::Header->instance;

my $cookie1 = CGI::Cookie->new( -name => 'foo' );
my $cookie2 = CGI::Cookie->new( -name => 'bar' );
my $cookie3 = CGI::Cookie->new( -name => 'baz' );

my $one   = $cookie1;
my $two   = [ $cookie1, $cookie2 ];
my $three = [ $cookie1, $cookie2, $cookie3 ];

cmpthese(100000, {
    one => sub {
       $blosxom::header->{-cookie} = $one; 
       my $cookie = $header->get_cookie( 'foo' );
    },
    two => sub {
       $blosxom::header->{-cookie} = $two; 
       my $cookie = $header->get_cookie( 'foo' );
    },
    three => sub {
       $blosxom::header->{-cookie} = $three; 
       my $cookie = $header->get_cookie( 'foo' );
    },
});

cmpthese(100000, {
    one => sub {
       $blosxom::header->{-cookie} = $one; 
       my $cookie = $header->get_cookie( 'bar' );
    },
    two => sub {
       $blosxom::header->{-cookie} = $two; 
       my $cookie = $header->get_cookie( 'bar' );
    },
    three => sub {
       $blosxom::header->{-cookie} = $three; 
       my $cookie = $header->get_cookie( 'bar' );
    },
});

cmpthese(100000, {
    one => sub {
       $blosxom::header->{-cookie} = $one; 
       my $cookie = $header->get_cookie( 'baz' );
    },
    two => sub {
       $blosxom::header->{-cookie} = $two; 
       my $cookie = $header->get_cookie( 'baz' );
    },
    three => sub {
       $blosxom::header->{-cookie} = $three; 
       my $cookie = $header->get_cookie( 'baz' );
    },
});
