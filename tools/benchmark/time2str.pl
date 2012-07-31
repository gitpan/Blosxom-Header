use strict;
use warnings;
use Benchmark qw/cmpthese/;
use CGI::Util qw/expires/;
use HTTP::Date;

my $now = time;

cmpthese(100000, {
    'CGI::Util'  => sub { my $date = expires( $now )  },
    'HTTP::Date' => sub { my $date = time2str( $now ) },
});
