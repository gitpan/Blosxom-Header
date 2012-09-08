use strict;
use warnings;
use Blosxom::Header;
use Test::More tests => 5;

{
    package blosxom;
    our $header = {};
}

my $class = 'Blosxom::Header';

ok !$class->has_instance, "no $class instance yet";

my $h1 = $class->instance;
ok $h1, "created $class instance 1";

my $h2 = $class->instance;
ok $h2, "created $class instance 2";

ok $h1 eq $h2, 'both instances are the same object';
ok $class->has_instance eq $h1, "$class has instance";

#$h1->DESTROY;
#is $h1->content_type, 'text/html', 'feature';
