use strict;
use FindBin;
use Test::More tests => 2 * 2 + 1;

{
    package blosxom;
    our $header = {};
    our $static_entries = 0;
    our $plugin_dir = "$FindBin::Bin/plugins";
}

my @plugins = qw( foo bar );

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
);

is_deeply $blosxom::header, \%expected;
