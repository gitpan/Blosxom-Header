use strict;
use Test::More;
use Blosxom::Header;

for my $field (qw(type nph expires cookie charset attachment p3p)) {
    {
        my $headers = { $field => 'foo' };
        my $h = Blosxom::Header->new($headers);
        is $h->$field(), 'foo';
    }

    {
        my $headers = { foo => 'bar' };
        my $h = Blosxom::Header->new($headers);
        $h->$field('baz');
        is_deeply $headers, { foo => 'bar', $field => 'baz' };
    }

    {
        my $headers = {};
        my $h = Blosxom::Header->new($headers);
        $h->$field(q{});
        is_deeply $headers, { $field => q{} }, 'set empty string';
    }
}

done_testing;
