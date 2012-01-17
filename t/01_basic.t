use strict;
use Test::More tests => 8;
use Blosxom::Header;

{
    package blosxom;

    our $header = {
        -type => 'text/html',
    };
}

{
    my $header = Blosxom::Header->new();

    isa_ok($header, 'Blosxom::Header');
    can_ok($header, qw/new remove set DESTROY/);
    is_deeply($header, {'Content-Type' => 'text/html'});

    $header->{'Content-Length'} = '1234';
}

is_deeply($blosxom::header, {
    '-Content-Type'   => 'text/html',
    '-Content-Length' => '1234',
});

# override
{
    my $header = Blosxom::Header->new();
    $header->{'Content-Type'} = 'text/plain';

    is_deeply($header, {
        'Content-Type'   => 'text/plain',
        'Content-Length' => '1234',
    });
}

is_deeply($blosxom::header, {
    '-Content-Type'   => 'text/plain',
    '-Content-Length' => '1234',
});

{
    my $header = Blosxom::Header->new();
    delete $header->{'Content-Length'};

    is_deeply($header, {'Content-Type' => 'text/plain'});
}

is_deeply($blosxom::header, {
    '-Content-Type' => 'text/plain',
});
