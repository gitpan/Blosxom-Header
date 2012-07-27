use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header;

{
    package blosxom;
    our $header = {};
}

my $header = Blosxom::Header->instance;

my @headers = (
    -type       => 'text/plain',
    -charset    => 'utf-8',
    -attachment => 'genome.jpg',
    -target     => 'ResultsWindow',
    -foo        => 'bar',
    -bar        => 'baz',
);

cmpthese(100000, {
    'Content-Type' => sub {
        %{ $blosxom::header } = @headers;
        my $deleted = delete $header->{Content_Type};
    },
    'Content-Disposition' => sub {
        %{ $blosxom::header } = @headers;
        my $deleted = delete $header->{Content_Disposition};
    },
    'Foo' => sub {
        %{ $blosxom::header } = @headers;
        my $deleted = delete $header->{Foo};
    },
    'Bar' => sub {
        %{ $blosxom::header } = @headers;
        my $deleted = delete $header->{Bar};
    },
});
