use strict;
use Test::More tests => 9;
use Blosxom::Header;

{
    package blosxom;

    our $header = {
        -type          => 'text/html;',
        -status        => '304 Not Modified',
        -cache_control => 'must-revalidate',
    };
}

my $header  = Blosxom::Header->new();
my @methods = qw(new get exists remove set);

isa_ok($header, 'Blosxom::Header');
can_ok($header,  @methods);
is_deeply($header, $blosxom::header);

# Blosxom::Header->get()
{
    my $got      = $header->get('type');
    my $expected = 'text/html;';

    is($got, $expected);
}

# Blosxom::Header->exists()
{
    my $got      = $header->exists('type');
    my $expected = 1;

    is($got, $expected);
}

{
    my $got      = $header->exists('content_length');
    my $expected = q{};

    is($got, $expected);
}

# Blosxom::Header->set()
$header->set( 'content_length' => '1234' );

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
$header->set(
    'type'   => 'text/plain;',
    'status' => '404',
);

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
$header->remove('cache_control', 'content_length');

{
    my $expected = {
        -type   => 'text/plain;',
        -status => '404 Not Found',
    };

    is_deeply($blosxom::header, $expected);
}

