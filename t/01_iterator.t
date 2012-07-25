use strict;
use warnings;
#use Test::More tests => 10;
use Test::More skip_all => 'deprecated';

BEGIN {
    use_ok 'Blosxom::Header::Iterator';
}

my $class = 'Blosxom::Header::Iterator';
can_ok $class, qw( new denormalize );
#ok $class->denormalize( '-foo' ) eq 'Foo';
#ok $class->denormalize( '-foo_bar' ) eq 'Foo-bar';

my %iteratee = (
    -status     => 1,
    -target     => 1,
    -p3p        => 1,
    -cookie     => 1,
    -expires    => 1,
    -nph        => 1,
    -attachment => 1,
    -foo        => 1,
    -type       => 1,
);

#my $iterator = $class->new(
#    -status     => 1,
#    -target     => 1,
#    -p3p        => 1,
#    -cookie     => 1,
#    -expires    => 1,
#    -nph        => 1,
#    -attachment => 1,
#    -foo        => 1,
#    -type       => 1,
#);
my $iterator = $class->new( \%iteratee );

ok $iterator->isa( $class );
#can_ok $iterator, qw( next has_next size current );
can_ok $iterator, qw( next has_next );
#ok $iterator->size == 9;
#ok $iterator->current == 0;

warn q{};
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );
#_warn( $iterator->next );


while ( $iterator->has_next ) {
    _warn( $iterator->next );
}

die;

sub _warn {
    my $next = shift || q{};
    warn "[ $next ]";
}

my @got;
while ( $iterator->has_next ) {
    push @got, $iterator->next;
}

my @expected = qw(
    Status
    Window-Target
    P3P
    Set-Cookie
    Expires
    Date
    Content-Disposition
    Foo
    Content-Type
);

is_deeply \@got, \@expected;
ok $iterator->current == 9;
