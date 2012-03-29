use strict;
use Blosxom::Header;
use Test::Base;
plan tests => 1 * blocks;

run {
    my $block  = shift;
    my $output = Blosxom::Header::_norm( $block->input );
    is $output, $block->expected;
};

__DATA__
===
--- input:    foo
--- expected: foo
===
--- input:    Foo
--- expected: foo
===
--- input:    -foo
--- expected: foo
===
--- input:    -Foo
--- expected: foo
===
--- input:    foo-bar
--- expected: foo-bar
===
--- input:    Foo-bar
--- expected: foo-bar
===
--- input:    Foo-Bar
--- expected: foo-bar
===
--- input:    foo_bar
--- expected: foo-bar
===
--- input:    Foo_bar
--- expected: foo-bar
===
--- input:    Foo_Bar
--- expected: foo-bar
===
--- input:    -foo-bar
--- expected: foo-bar
===
--- input:    -Foo-bar
--- expected: foo-bar
===
--- input:    -Foo-Bar
--- expected: foo-bar
===
--- input:    -foo_bar
--- expected: foo-bar
===
--- input:    -Foo_bar
--- expected: foo-bar
===
--- input:    -Foo_Bar
--- expected: foo-bar
===
--- input:    type
--- expected: type
===
--- input:    content-type
--- expected: type
===
--- input:    cookie
--- expected: cookie
===
--- input:    set-cookie
--- expected: cookie
