use strict;
use Test::More;
use Blosxom::Header;

is Blosxom::Header::_lc('Foo'), '-foo';
is Blosxom::Header::_lc('foo'), '-foo';

is Blosxom::Header::_lc('Content-Type'), '-type';
is Blosxom::Header::_lc('content-type'), '-type';

is Blosxom::Header::_lc('Type'), '-type';
is Blosxom::Header::_lc('type'), '-type';

done_testing;
