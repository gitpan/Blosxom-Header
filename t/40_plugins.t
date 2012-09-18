use strict;
use FindBin;
use Test::More;

my @plugins = qw( foo bar baz );

plan tests => @plugins * 2 + 1;

{
    package blosxom;
    our $header = {};
    our $static_entries = 0;
    our $plugin_dir = "$FindBin::Bin/plugins";
}

for my $plugin ( @plugins ) {
    require_ok "$blosxom::plugin_dir/$plugin";
    ok $plugin->start;
}

for my $plugin ( @plugins ) {
    $plugin->last;
}

my %expected = (
    -foo => 'bar',
    -bar => 'baz',
    -baz => 'qux',
);

is_deeply $blosxom::header, \%expected;
