use strict;
use Blosxom::Header::Adapter;
use Test::Base;

plan tests => 1 * blocks();

my $adapter = Blosxom::Header::Adapter->TIEHASH;

run {
    my $block = shift;
    is $adapter->denormalize( $block->input ), $block->expected;
};

__DATA__
===
--- input:    -foo
--- expected: Foo
===
--- input:    -foo_bar
--- expected: Foo-bar
===
--- input:    -target
--- expected: Window-Target
===
--- input:    -p3p
--- expected: P3P
===
--- input:    -attachment
--- expected: Content-Disposition
===
--- input:    -type
--- expected: Content-Type
===
--- input:    -cookie
--- expected: Set-Cookie
