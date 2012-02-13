use strict;
use Test::More;
use Blosxom::Header;

my @tests = (
    [qw(foo      foo    )],
    [qw(Foo      foo    )],
    [qw(-foo     foo    )],
    [qw(-Foo     foo    )],
    [qw(foo_bar  foo-bar)],
    [qw(Foo_Bar  foo-bar)],
    [qw(-foo_bar foo-bar)],
    [qw(-Foo_Bar foo-bar)],
);

for my $test (@tests) {
    my ($input, $output) = @$test;
    is Blosxom::Header::_lc($input), $output;
}

done_testing;
