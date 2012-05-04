use strict;
use Blosxom::Header;
use Test::Base;
plan tests => 1 * blocks;

run {
    my $block = shift;
    my $got = Blosxom::Header::_normalize_field_name( $block->input );
    is $got, $block->expected;
};

__DATA__
===
--- input:    -foo
--- expected: foo
===
--- input:    -Foo
--- expected: foo
===
--- input:    foo
--- expected: foo
===
--- input:    Foo
--- expected: foo
===
--- input:    -foo-bar
--- expected: foo_bar
===
--- input:    -Foo-bar
--- expected: foo_bar
===
--- input:    -Foo-Bar
--- expected: foo_bar
===
--- input:    -foo_bar
--- expected: foo_bar
===
--- input:    -Foo_bar
--- expected: foo_bar
===
--- input:    -Foo_Bar
--- expected: foo_bar
===
--- input:    foo-bar
--- expected: foo_bar
===
--- input:    Foo-bar
--- expected: foo_bar
===
--- input:    Foo-Bar
--- expected: foo_bar
===
--- input:    foo_bar
--- expected: foo_bar
===
--- input:    Foo_bar
--- expected: foo_bar
===
--- input:    Foo_Bar
--- expected: foo_bar
===
--- input:    -type
--- expected: type
=== 
--- input:    -content-type
--- expected: type
===
--- input:    -cookie
--- expected: cookie
===
--- input:    -cookies
--- expected: cookie
===
--- input:    -set-cookie
--- expected: cookie
