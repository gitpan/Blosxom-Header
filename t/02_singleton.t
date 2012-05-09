use strict;
use Blosxom::Header;
use Blosxom::Header::Class;
use Test::More tests => 10;

{
    package blosxom;
    our $header = { -type => 'text/html' };
}

ok !$Blosxom::Header::INSTANCE, 'no Blosxom::Header instance yet';

{
    my $h1 = tie my %h1, 'Blosxom::Header';
    ok $h1, 'created Blosxom::Header instance 1';

    my $h2 = tie my %h2, 'Blosxom::Header';
    ok $h2, 'created Blosxom::Header instance 2';

    is $h1, $h2, 'both instances are the same object';
    is $Blosxom::Header::INSTANCE, $h1, 'Blosxom::Header has instance';
}

ok !$Blosxom::Header::Class::INSTANCE, 'no Blosxom::Header::Class instance yet';

{
    my $h1 = Blosxom::Header::Class->instance;
    ok $h1, 'created Blosxom::Header::Class instance 1';

    my $h2 = Blosxom::Header::Class->instance;
    ok $h2, 'created Blosxom::Header::Class instance 2';

    is $h1, $h2, 'both instances are the same object';
    is $Blosxom::Header::Class::INSTANCE, $h1, 'Blosxom::Header::Class has instance';
}


