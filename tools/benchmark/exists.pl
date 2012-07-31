use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header;

{
    package blosxom;

    our $header = {
        -type    => 'text/plain',
        -charset => 'utf-8',
        -nph     => 1,
        -foo     => 'bar',
    };
}

my $header = Blosxom::Header->new;

cmpthese(100000, {
    'Content-Type' => sub {
        my $bool = exists $header->{Content_Type};
    },
    'Content-Disposition' => sub {
        my $bool = exists $header->{Content_Disposition};
    },
    'Date' => sub {
        my $bool = exists $header->{Date};
    },
    'Foo' => sub {
        my $bool = exists $header->{Foo};
    },
});
