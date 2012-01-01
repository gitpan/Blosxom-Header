use strict;
use Test::More tests => 2;
use Test::Warn;
use Blosxom::Header;

{
    package blosxom;
    our $header;
}

warning_is { Blosxom::Header->new() }
    { carped => q{$blosxom::header haven't been initialized yet.} };

$blosxom::header = {};
my $header = Blosxom::Header->new();

warning_is { $header->set( 'status' => '123' ) }
    { carped => q{Unknown status code: 123} };
