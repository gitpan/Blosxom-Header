use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header;
use CGI::Cookie;

{
    package blosxom;
    our $header = {};
}

my $header = Blosxom::Header->new;

cmpthese(3000, {
    five => sub {
        delete $blosxom::header->{-cookie};
        for my $n ( 1 .. 5 ) {
            $header->set_cookie( "foo_$n" => "bar_$n" );
        }
    },
    ten => sub {
        delete $blosxom::header->{-cookie};
        for my $n ( 1 .. 10 ) {
            $header->set_cookie( "foo_$n" => "bar_$n" );
        }
    },
    fifteen => sub {
        delete $blosxom::header->{-cookie};
        for my $n ( 1 .. 15 ) {
            $header->set_cookie( "foo_$n" => "bar_$n" );
        }
    },
    twenty => sub {
        delete $blosxom::header->{-cookie};
        for my $n ( 1 .. 20 ) {
            $header->set_cookie( "foo_$n" => "bar_$n" );
        }
    },
});

my @five;
for my $n ( 1 .. 5 ) {
    push @five, CGI::Cookie->new( "foo_$n" => "bar_$n" );
}

my @ten = @five;
for my $n ( 6 .. 10 ) {
    push @ten, CGI::Cookie->new( "foo_$n" => "bar_$n" );
}

my @fifteen = @ten;
for my $n ( 11 .. 15 ) {
    push @fifteen, CGI::Cookie->new( "foo_$n" => "bar_$n" );
}

my @twenty = @fifteen;
for my $n ( 16 .. 20 ) {
    push @twenty, CGI::Cookie->new( "foo_$n" => "bar_$n" );
}

cmpthese(7000, {
    five => sub {
        $blosxom::header->{-cookie} = \@five;
        $header->set_cookie( foo => 'bar' );
    },
    ten => sub {
        $blosxom::header->{-cookie} = \@ten;
        $header->set_cookie( foo => 'bar' );
    },
    fifteen => sub {
        $blosxom::header->{-cookie} = \@fifteen;
        $header->set_cookie( foo => 'bar' );
    },
    twenty => sub {
        $blosxom::header->{-cookie} = \@twenty;
        $header->set_cookie( foo => 'bar' );
    },
});
