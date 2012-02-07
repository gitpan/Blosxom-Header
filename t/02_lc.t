use strict;
use Test::More;
use Blosxom::Header;

my @tests = (
    [qw(-foo foo)],
    [qw(-Foo foo)],
    [qw(foo  foo)],
    [qw(Foo  foo)],
);

for my $test (@tests) {
    is Blosxom::Header::_lc($test->[0]), $test->[1];
}

done_testing;
