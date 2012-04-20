use strict;
use Blosxom::Header;
use Test::More;

{
    package blosxom;
    our $header;
}

{
    undef $blosxom::header;
    eval { Blosxom::Header->new };
    like $@, qr{^Not a HASH reference};
}

{
    undef $blosxom::header;
    my $header_ref = {};
    my $header = Blosxom::Header->new( $header_ref );
    isa_ok $header, 'Blosxom::Header';
    can_ok $header, qw( new get set push_cookie push_p3p exists delete );
    is $header->{header}, $header_ref;
}

{
    $blosxom::header = {};
    my $header = Blosxom::Header->new;
    is $header->{header}, $blosxom::header;
}

{
    $blosxom::header = {};
    my $header_ref = {};
    my $header = Blosxom::Header->new( $header_ref );
    is $header->{header}, $header_ref;
}

done_testing;
