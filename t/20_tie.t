use strict;
use Blosxom::Header;
use Data::Dumper;
use Test::More;

{
    package blosxom;
    our $header = { -type => 'text/html' };
}

{
    tie my %header, 'Blosxom::Header';
    is $header{Content_Type}, 'text/html', 'get';
    ok exists $header{Content_Type}, 'exists';
    ok %header;

    $header{Status} = '304 Not Modified';
    is $blosxom::header->{-status}, '304 Not Modified', 'set';

    is_deeply [ @header{'Content_Type', 'Status'} ],
              [ 'text/html', '304 Not Modified' ], 'slice';
              
    $header{Last_Modified} = 'foo';
    is_deeply [ sort keys %header ], [ 'Last-modified', 'status', 'type' ], 'keys';

    is delete $header{Status}, '304 Not Modified', 'delete';
    my %expected = ( -type => 'text/html', '-last-modified' => 'foo' );
    is_deeply $blosxom::header, \%expected;

    my @cookies = ( 'foo', 'bar' );
    $header{Set_Cookie} = \@cookies;
    is $header{Set_Cookie}, \@cookies, 'should return arrayref';

    %header = ();
    is_deeply $blosxom::header, {}, 'clear';
    ok !%header;
}

done_testing;
