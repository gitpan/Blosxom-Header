use strict;
use Test::More tests => 4;
use Test::Warn;
use Blosxom::Header;

{
    package blosxom;

    our $header = {
        -type => 'text/html',
    };
}

{
    my $header = Blosxom::Header->new();
    $header->{'Status'} = '304';
}

is_deeply($blosxom::header, {
    '-Content-Type' => 'text/html',
    '-Status'       => '304 Not Modified',
});

{
    my $header = Blosxom::Header->new();
    $header->set( 'Status'=> '404' );
}

is_deeply($blosxom::header, {
    '-Content-Type' => 'text/html',
    '-Status'       => '404 Not Found',
});

{
    my $header = Blosxom::Header->new();
    $header->set( 'Status'=> '123' );
    warning_is { $header->DESTROY }
        { carped => q{Unknown status code: 123} };
}

is_deeply($blosxom::header, {
    '-Content-Type' => 'text/html',
    '-Status'       => '123',
});
