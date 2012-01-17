use strict;
use Test::More tests => 1;
use CGI qw(header);

my $got = header(
    '-Cache-Control' => 'must-revalidate',
    '-Status'        => '304 Not Modified',
    '-Content-Type'  => 'text/html; charset=UTF-8',
);

my $expected = "Status: 304 Not Modified$CGI::CRLF"
             . "Cache-control: must-revalidate$CGI::CRLF"
             . "Content-Type: text/html; charset=UTF-8$CGI::CRLF"
             . $CGI::CRLF;

is($got, $expected);

