use strict;
use Blosxom::Header;
use Test::More tests => 9;
use Test::Warn;
use Test::Exception;

{
    package blosxom;
    our $header;
}

{
    my $expected = qr{^\$blosxom::header hasn't been initialized yet};
    throws_ok { Blosxom::Header->instance } $expected;
}

# Initialize
my %header;
$blosxom::header = \%header;

my $header = Blosxom::Header->instance;
isa_ok $header, 'Blosxom::Header';
can_ok $header, qw(
    clear delete exists field_names get set
    as_hashref is_empty flatten
    content_type type charset
    p3p_tags push_p3p_tags 
    last_modified date expires
    attachment charset nph status target
    set_cookie get_cookie
);

subtest 'date()' => sub {
    %header = ();
    is $header->date, undef;

    my $now = 1341637509;
    $header->date( $now );
    is $header->date, $now;
    is $header{-date}, 'Sat, 07 Jul 2012 05:05:09 GMT';
};

subtest 'last_modified()' => sub {
    %header = ();
    is $header->last_modified, undef;

    my $now = 1341637509;
    $header->last_modified( $now );
    is $header->last_modified, $now;
    is $header{-last_modified}, 'Sat, 07 Jul 2012 05:05:09 GMT';
};

subtest 'status()' => sub {
    %header = ();
    is $header->status, undef;
    $header->status( 304 );
    is $header{-status}, '304 Not Modified';
    is $header->status, '304';
    my $expected = 'Unknown status code "999" passed to status()';
    warning_is { $header->status( 999 ) } $expected;
};

subtest 'charset()' => sub {
    %header = ();
    is $header->charset, 'ISO-8859-1';

    %header = ( -charset => q{} );
    is $header->charset, undef;

    %header = ( -type => q{} );
    is $header->charset, undef;

    %header = ( -type => 'text/html; charset=euc-jp' );
    is $header->charset, 'EUC-JP';

    %header = ( -type => 'text/html; charset=iso-8859-1; Foo=1' );
    is $header->charset, 'ISO-8859-1';

    %header = ( -type => 'text/html; charset="iso-8859-1"; Foo=1' );
    is $header->charset, 'ISO-8859-1';

    %header = ( -type => 'text/html; charset = "iso-8859-1"; Foo=1' );
    is $header->charset, 'ISO-8859-1';

    %header = ( -type => 'text/html;\r\n charset = "iso-8859-1"; Foo=1' );
    is $header->charset, 'ISO-8859-1';

    %header = ( -type => 'text/html;\r\n charset = iso-8859-1 ; Foo=1' );
    is $header->charset, 'ISO-8859-1';

    %header = ( -type => 'text/html;\r\n charset = iso-8859-1 ' );
    is $header->charset, 'ISO-8859-1';
};

subtest 'content_type()' => sub {
    %header = ();
    is $header->content_type, 'text/html';
    my @got = $header->content_type;
    my @expected = ( 'text/html', 'charset=ISO-8859-1' );
    is_deeply \@got, \@expected;

    %header = ( -type => 'text/plain; charset=EUC-JP' );
    is $header->content_type, 'text/plain';
    @got = $header->content_type;
    @expected = ( 'text/plain', 'charset=EUC-JP' );
    is_deeply \@got, \@expected;

    %header = ( -type => 'text/plain; charset=EUC-JP; Foo=1' );
    is $header->content_type, 'text/plain';
    @got = $header->content_type;
    @expected = ( 'text/plain', 'charset=EUC-JP; Foo=1' );
    is_deeply \@got, \@expected;

    %header = ( -charset => 'utf-8' );
    $header->content_type( 'text/plain; charset=EUC-JP' );
    is_deeply $blosxom::header, { -type => 'text/plain; charset=EUC-JP' };

    %header = ( -type => 'text/plain', -charset => 'utf-8' );
    @got = $header->content_type;
    @expected = ( 'text/plain', 'charset=utf-8' );
    is_deeply \@got, \@expected;

    %header = ( -type => 'text/plain; Foo=1', -charset => 'utf-8' );
    @got = $header->content_type;
    @expected = ( 'text/plain', 'Foo=1; charset=utf-8' );
    is_deeply \@got, \@expected;

    %header = (
        -type    => 'text/plain; charset=euc-jp',
        -charset => 'utf-8',
    );
    @got = $header->content_type;
    @expected = ( 'text/plain', 'charset=euc-jp' );
    is_deeply \@got, \@expected;

    %header = ( -type => q{} );
    is $header->content_type, q{};
};

subtest 'target()' => sub {
    %header = ();
    is $header->target, undef;
    $header->target( 'ResultsWindow' );
    is $header->target, 'ResultsWindow';
    is_deeply \%header, { -target => 'ResultsWindow' };
};
