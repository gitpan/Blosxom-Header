use strict;
use Blosxom::Header;
use Test::More;

{
    my $header = Blosxom::Header->new({ -expires => 'now' });
    can_ok $header, qw/attachment charset cookie expires nph target p3p type/;
    is $header->expires, 'now';
    is $header->expires( '+1d' ), '+1d';
    is_deeply $header->{header}, { -expires => '+1d' };
}

done_testing;
