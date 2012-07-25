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

my $header = Blosxom::Header->instance;
my $instance = Blosxom::Header->instance;

$header->set(
    Content_type        => 'text/plain',
    Status              => '304 Not Modified',
    Content_Disposition => 'inline',
    P3P                 => [qw/CAO DSP LAW CURa/],
    Set_Cookie          => 'ID=123456; path=/',
);
    
my @values = $header->get(qw/Content-Type Status P3P Set-Cookie/);
my @fields = $header->field_names;
my @headers = $header->flatten;
my $exists = $header->exists( 'ETag' );
my $is_empty = $header->is_empty;

@values = ();
$header->each(sub {
    my ( $field, $value ) = @_;
    push @values, $value;
});

$header->delete(qw/Content-Disposition Content-Length/);

my $code = $header->status;
$header->status( 404 );

$header->set_cookie( ID => 123456 );
my $cookie = $header->get_cookie( 'ID' );

$header->expires( '+3M' );
my $expires = $header->expires;

$header->last_modified( time );
my $last_modified = $header->last_modified;

my $date = $header->date;

$header->attachment( 'genome.jpg' );
my $attachment = $header->attachment;

$header->nph( 1 );
my $nph = $header->nph;

$header->p3p_tags(qw/CAO DSP LAW CURa/);
my @tags = $header->p3p_tags;

$header->target( 'ResultsWindow' );
my $target = $header->target;

$header->clear;
