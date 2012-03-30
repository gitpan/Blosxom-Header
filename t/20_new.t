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
    my $h = Blosxom::Header->new( $header_ref );
    isa_ok $h, 'Blosxom::Header::Class';
    can_ok $h, qw( new get set push exists delete );
    is $h->{header}, $header_ref;
}

{
    $blosxom::header = {};
    my $h = Blosxom::Header->new;
    is $h->{header}, $blosxom::header;
}

{
    $blosxom::header = {};
    my $header_ref = {};
    my $h = Blosxom::Header->new( $header_ref );
    is   $h->{header}, $header_ref;
    isnt $h->{header}, $blosxom::header;
}

done_testing;
