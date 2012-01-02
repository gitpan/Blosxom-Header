use strict;
use Test::More tests => 8;
use Blosxom::Header;

{
    package blosxom;

    our $header = {
        -type          => 'text/html;',
        -status        => '304 Not Modified',
        -cache_control => 'must-revalidate',
    };
}

{
    my $header  = Blosxom::Header->new();
    my @methods = qw(new get exists remove set DESTROY);

    isa_ok($header, 'Blosxom::Header');
    can_ok($header,  @methods);
    is($header->get('type'), 'text/html;');
    is($header->exists('type'), 1);
    is($header->exists('content_length'), q{});
    $header->set( 'content_length' => '1234' );
}

{
    my $expected = {
        -type           => 'text/html;',
        -status         => '304 Not Modified',
        -cache_control  => 'must-revalidate',
        -content_length => '1234',
    };

    is_deeply($blosxom::header, $expected);
}

# override
{
    my $header = Blosxom::Header->new();
    $header->set(
        'type'   => 'text/plain;',
        'status' => '404',
    );
}

{
    my $expected = {
        -type           => 'text/plain;',
        -status         => '404 Not Found',
        -cache_control  => 'must-revalidate',
        -content_length => '1234',
    };

    is_deeply($blosxom::header, $expected);
}

# Blosxom::Header->remove()
{
    my $header = Blosxom::Header->new();
    $header->remove('cache_control', 'content_length');
}

{
    my $expected = {
        -type   => 'text/plain;',
        -status => '404 Not Found',
    };

    is_deeply($blosxom::header, $expected);
}

