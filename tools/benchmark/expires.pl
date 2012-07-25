use strict;
use warnings;
use Benchmark qw/timethese cmpthese/;
use CGI::Util qw/expires/;

my %cache;
my $expires = sub {
    my $time = shift;
    $cache{ $time } ||= expires( $time );
};

sub baz { $expires->( @_ ) }

my $result = timethese(10000, {
    foo => sub { expires( '+3M' ) },
    bar => sub { $expires->( '+3M' ) },
    baz => sub { baz( '+3M' ) },
});

cmpthese( $result );
