use strict;
use Blosxom::Header;
use Test::Base;
plan tests => 1 * blocks;

run {
    my $block = shift;
    my $got = Blosxom::Header::_denormalize_field_name( $block->input );
    is $got, $block->expected;
};

__DATA__
===
--- input:    -foo
--- expected: Foo
===
--- input:    -foo-bar
--- expected: Foo-bar
===
--- input:    -attachment
--- expected: attachment
===
--- input:    -charset
--- expected: charset
===
--- input:    -cookie
--- expected: cookie
===
--- input:    -expires
--- expected: expires
===
--- input:    -nph
--- expected: nph
===
--- input:    -p3p
--- expected: p3p
===
--- input:    -status
--- expected: status
===
--- input:    -target
--- expected: target
===
--- input:    -type
--- expected: type
