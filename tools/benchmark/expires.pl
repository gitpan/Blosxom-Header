use strict;
use warnings;
use Benchmark qw/cmpthese/;
use CGI::Util;

my %expires_ref;
my $expires_ref = sub {
    my $time = shift;
    $expires_ref{ $time } ||= CGI::Util::expires( $time );
};

my %expires;
sub expires {
    my $time = shift;
    $expires{ $time } ||= CGI::Util::expires( $time );
}

my $now = time;

cmpthese(1000000, {
    'CGI::Util::expires()'      => sub { CGI::Util::expires( $now ) },
    '$expires_ref->() (cached)' => sub { $expires_ref->( $now )     },
    'expires() (cached)'        => sub { expires( $now )            },
});

