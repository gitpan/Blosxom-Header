use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header;
use HTTP::Date;

{
    package blosxom;
    our $header = {};
}

my $header = Blosxom::Header->new;
my $now = time2str( time );

cmpthese(100000, {
    'Content-Type' => sub {
        %{ $blosxom::header } = ();
        $header->{Content_Type} = 'text/plain; charset=utf-8';
    },
    'Content-Disposition' => sub {
        %{ $blosxom::header } = ();
        $header->{Content_Disposition} = 'inline';
    },
    'Date' => sub {
        %{ $blosxom::header } = ();
        $header->{Date} = 'Thu, 25 Apr 1999 00:40:33 GMT';
    },
    'Expires' => sub {
        %{ $blosxom::header } = ();
        $header->{Expires} = '+3M';
    },
    'Set-Cookie' => sub {
        %{ $blosxom::header } = ();
        $header->{Set_Cookie} = 'ID=123456; path=/';
    },
    'Foo' => sub {
        %{ $blosxom::header } = ();
        $header->{Foo} = 'bar';
    },
});

$now = time;

cmpthese(200000, {
    'content_type' => sub {
        %{ $blosxom::header } = ();
        $header->content_type( 'text/plain; charset=utf-8' );
    },
    'attachment' => sub {
        %{ $blosxom::header } = ();
        $header->attachment( 'genome.jpg' );
    },
    'date' => sub {
        %{ $blosxom::header } = ();
        $header->date( $now );
    },
    'expires' => sub {
        %{ $blosxom::header } = ();
        $header->expires( $now );
    },
    'last_modified' => sub {
        %{ $blosxom::header } = ();
        $header->last_modified( $now );
    },
    'status' => sub {
        %{ $blosxom::header } = ();
        $header->status( 304 );
    },
    'target' => sub {
        %{ $blosxom::header } = ();
        $header->target( 'ResultsWindow' );
    },
    'nph' => sub {
        %{ $blosxom::header } = ();
        $header->nph( 1 );
    },
});
