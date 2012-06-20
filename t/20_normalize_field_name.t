use strict;
use Blosxom::Header::Proxy;
use Test::Base;

plan tests => 2 * blocks;

my $proxy = tie my %proxy => 'Blosxom::Header::Proxy';

run {
    my $block = shift;
    is $proxy->norm_of( $block->input ),      $block->norm;
    is $proxy->field_name_of( $block->norm ), $block->field_name;
};

__DATA__
===
--- input:      -foo
--- norm:       -foo
--- field_name: Foo
===
--- input:      -Foo
--- norm:       -foo
--- field_name: Foo
===
--- input:      foo
--- norm:       -foo
--- field_name: Foo
===
--- input:      Foo
--- norm:       -foo
--- field_name: Foo
===
--- input:      -foo-bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      -Foo-bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      -Foo-Bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      -foo_bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      -Foo_bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      -Foo_Bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      foo-bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      Foo-bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      Foo-Bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      foo_bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:      Foo_bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- input:       Foo_Bar
--- norm:       -foo_bar
--- field_name: Foo-bar
===
--- SKIP
--- input:    -type
--- expected: -type
=== 
--- SKIP
--- input:    -content_type
--- expected: -type
===
--- input:      -cookie
--- norm:       -cookie
--- field_name: Set-Cookie
===
--- input:      -cookies
--- norm:       -cookie
--- field_name: Set-Cookie
===
--- input:      -set_cookie
--- norm:       -cookie
--- field_name: Set-Cookie
===
--- input:      -window_target
--- norm:       -target
--- field_name: Window-Target
===
--- input:      -target
--- norm:       -target
--- field_name: Window-Target
===
--- input:      -attachment
--- norm:       -attachment
--- field_name: Content-Disposition
===
--- input:      -content_disposition
--- norm:       -content_disposition
--- field_name: Content-disposition
===
--- input:      -p3p
--- norm:       -p3p
--- field_name: P3P
