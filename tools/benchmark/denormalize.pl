use strict;
use warnings;
use Benchmark qw/timethese cmpthese/;

my $denormalize1 = sub {
    my $norm = shift;
    ( my $field = $norm ) =~ s/^-//;
    $field =~ tr/_/-/;
    ucfirst $field;
};

my %cache;
my $denormalize2 = sub {
    my $norm = shift;
    unless ( exists $cache{ $norm } ) {
        ( my $field = $norm ) =~ s/^-//;
        $field =~ tr/_/-/;
        return $cache{ $norm } = ucfirst $field;
    }
    $cache{ $norm };
};

my @norms = qw(
    -foo -bar -baz
    -foo_bar -bar_foo
    -foo_bar_baz -foo_baz_bar
    -bar_foo_baz -bar_baz_foo
    -baz_foo_bar -baz_bar_foo
);

my $result = timethese(10000, {
    denormalize1 => sub { map { $denormalize1->( $_ ) } @norms },
    denormalize2 => sub { map { $denormalize2->( $_ ) } @norms },
});

cmpthese( $result );
