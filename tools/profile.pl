use strict;
use warnings;
use Blosxom::Header qw(
    header_get header_set header_delete
    header_exists header_iter
);

{
    package blosxom;
    our $header = {};
}

my $header = Blosxom::Header->new;


my $instance = Blosxom::Header->instance;
$instance = Blosxom::Header->instance;
$instance = Blosxom::Header->instance;
$instance = Blosxom::Header->instance;
$instance = Blosxom::Header->instance;


$header->set(
    Content_type        => 'text/plain',
    Status              => '304 Not Modified',
    Content_Disposition => 'inline',
    P3P                 => [qw/CAO DSP LAW CURa/],
    Set_Cookie          => 'ID=123456; path=/',
    Content_Length      => 3495,
    Location            => 'http://www.blosxom.com/',
    Cache_Control       => 'must-revalidate',
);

    
my @values = $header->get(qw/
    Content-Type
    Status
    P3P
    Set-Cookie
    Content-Disposition
    Location
    Content-Length
    Cache-Control
/);


my @fields = $header->field_names;
my @headers = $header->flatten;
my $is_empty = $header->is_empty;


my $exists = $header->exists( 'ETag' );
$exists = $header->exists( 'Content-Type' );
$exists = $header->exists( 'Content-Disposition' );
$exists = $header->exists( 'Status' );
$exists = $header->exists( 'P3P' );
$exists = $header->exists( 'Set-Cookie' );
$exists = $header->exists( 'Cache-Control' );


@values = ();
$header->each(sub {
    my ( $field, $value ) = @_;
    push @values, $value;
});


$header->delete(qw/
    Content-Disposition
    Content-Length
    Status
    P3P
    Set-Cookie
    ETag
/);

$header->delete(qw/Cache-Control Last-Modified/);


my $code = $header->status;
$header->status( 404 );

$code = $header->status;
$header->status( 304 );

$code = $header->status;
$header->status( 200 );


@fields = $header->field_names;
@headers = $header->flatten;
$is_empty = $header->is_empty;


$header->set_cookie( ID => 123456 );
my $cookie = $header->get_cookie( 'ID' );
$header->set_cookie(
    preferences => {
        value => {
            font => 'Helvetica',
            size => 12,
        },
    }
);
$cookie = $header->get_cookie( 'ID' );
$cookie = $header->get_cookie( 'preferences' );


$header->expires( '+30s' );
my $expires = $header->expires;

$header->expires( '+10m' );
$expires = $header->expires;

$header->expires( '+1h' );
$expires = $header->expires;

$header->expires( '-1d' );
$expires = $header->expires;

$header->expires( 'now' );
$expires = $header->expires;

$header->expires( '+3M' );
$expires = $header->expires;

$header->expires( '+10y' );
$expires = $header->expires;

$header->expires( 'Thu, 25 Apr 1999 00:40:33 GMT' );
$expires = $header->expires;

$header->expires( time );
$expires = $header->expires;


@fields = $header->field_names;
@headers = $header->flatten;
$is_empty = $header->is_empty;


$header->last_modified( time );
my $last_modified = $header->last_modified;

$header->last_modified( time+60 );
$last_modified = $header->last_modified;

$header->last_modified( time+60*2 );
$last_modified = $header->last_modified;

$header->last_modified( time+60*3 );
$last_modified = $header->last_modified;

$header->last_modified( time+60*4 );
$last_modified = $header->last_modified;

$header->last_modified( time+60*5 );
$last_modified = $header->last_modified;


my $date = $header->date;


$header->attachment( 'genome.jpg' );
my $attachment = $header->attachment;


$header->nph( 1 );
my $nph = $header->nph;

$header->nph( 0 );
$nph = $header->nph;

$header->nph( 1 );
$nph = $header->nph;

$header->nph( 0 );
$nph = $header->nph;

$header->nph( 1 );
$nph = $header->nph;

$header->nph( 0 );
$nph = $header->nph;


$header->push_p3p_tags( 'NOI' );
my @tags = $header->p3p_tags;

$header->push_p3p_tags( 'ADM' );
@tags = $header->p3p_tags;

$header->push_p3p_tags( 'DEV PSAi' );
@tags = $header->p3p_tags;

$header->push_p3p_tags(qw/COM NAV OUR/);
@tags = $header->p3p_tags;

$header->push_p3p_tags(qw/OTR STP/, 'IND DEM');
@tags = $header->p3p_tags;


$header->content_type( 'text/html; charset=utf-8' );
my $type = $header->content_type;
my @type = $header->content_type;

$header->content_type( 'text/plain; charset=utf-8' );
$type = $header->content_type;
@type = $header->content_type;

$header->content_type( 'text/html; charset=euc-jp' );
$type = $header->content_type;
@type = $header->content_type;

$header->content_type( 'text/plain; charset=euc-jp' );
$type = $header->content_type;
@type = $header->content_type;


$header->target( 'ResultsWindow' );
my $target = $header->target;


$header->clear;
