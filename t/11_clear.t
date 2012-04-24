use strict;
use Blosxom::Header;
use Test::More;

{
    my $header = Blosxom::Header->new({});
    $header->clear;
    is_deeply $header->{header}, {}, 'clear';
}

done_testing;
