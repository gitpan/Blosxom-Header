use strict;
use warnings;
use CGI qw/header/;
use Test::More tests => 2;

my %header;

{
    package blosxom;
    our $header = \%header;
}

package CGI::Header;
use base 'Blosxom::Header';

sub as_string {
    my $self = shift;

    my $result;
    $self->each(sub {
        my ( $field, $value ) = @_;
        $result .= "$field: $value$CGI::CRLF";
    });

    $result ? "$result$CGI::CRLF" : $CGI::CRLF x 2;
}

package main;

my $header = CGI::Header->new;
is $header->as_string, header( $blosxom::header );

%header = (
    -type       => 'text/plain',
    -charset    => 'utf-8',
    -attachment => 'genome.jpg',
    -p3p        => [qw/CAO DSP LAW CURa/],
    -target     => 'ResultsWindow',
    -foo        => 'bar',
    -status     => '304 Not Modified',
    -cookie     => 'ID=123456; path=/',
);
is $header->as_string, header( $blosxom::header );
