use strict;
use warnings;
use Blosxom::Header::Entity;
use CGI;
use Test::More tests => 2;

package Blosxom::Header::Entity;

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

my $header = Blosxom::Header::Entity->new;

is $header->as_string, CGI::header( $header->header );

%{ $header->header } = (
    -type       => 'text/plain',
    -charset    => 'utf-8',
    -attachment => 'genome.jpg',
    -target     => 'ResultsWindow',
    -foo_bar    => 'baz',
    -status     => '304 Not Modified',
    -cookie     => 'ID=123456; path=/',
);

is $header->as_string, CGI::header( $header->header );
