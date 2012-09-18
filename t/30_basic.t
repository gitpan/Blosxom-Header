use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

BEGIN {
    my @functions = qw(
        header_get    header_set  header_exists
        header_delete header_iter
    );
    use_ok 'Blosxom::Header', @functions;
    can_ok __PACKAGE__, @functions;
}

my $class = 'Blosxom::Header';
can_ok $class, qw( instance has_instance new );
ok $class->isa( 'Blosxom::Header::Entity' );

subtest 'new()' => sub {
    my $expected = qr{^Private method 'new' called for Blosxom::Header};
    throws_ok { $class->new } $expected, 'new() is private method';
};

subtest 'is_initialized()' => sub {
    local $blosxom::header;
    ok !$class->is_initialized;
    $blosxom::header = {};
    ok $class->is_initialized;
};

subtest 'instance()' => sub {
    local $blosxom::header;
    local $Blosxom::Header::INSTANCE;

    my $expected = qr{^Blosxom::Header hasn't been initialized yet};
    throws_ok { $class->instance } $expected;

    # initialize
    $blosxom::header = {};

    ok !$class->has_instance, "no $class instance yet";

    my $h1 = $class->instance;
    ok $h1, "created $class instance 1";
    ok $h1->isa( $class );
    is $h1->header, $blosxom::header;

    my $h2 = $class->instance;
    ok $h2, "created $class instance 2";

    ok $h1 eq $h2, 'both instances are the same object';
    ok $class->has_instance eq $h1, "$class has instance";
};

subtest 'functions' => sub {
    my %header;
    local $blosxom::header = \%header;
    local $Blosxom::Header::INSTANCE;

    is header_get( 'Content-Type' ), 'text/html; charset=ISO-8859-1';
    is header_get( 'Status' ), undef;

    ok header_exists( 'Content-Type' );
    ok !header_exists( 'Status' );

    header_set( Status => '304 Not Modified' );
    is_deeply \%header, { -status => '304 Not Modified' };

    is header_delete( 'Status' ), '304 Not Modified';
    is_deeply \%header, {};

    my @got;
    header_iter sub {
        my ( $field, $value ) = @_;
        push @got, $field, $value;
    };

    my @expected = ( 'Content-Type', 'text/html; charset=ISO-8859-1' );

    is_deeply \@got, \@expected;
};
