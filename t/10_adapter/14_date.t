use strict;
use Blosxom::Header;
use HTTP::Date;
use Test::More tests => 21;
use Test::Warn;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header', \%adaptee;

%adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
ok exists $adapter{Date};

%adaptee = ( -expires => 1341637509 );
is $adapter{Expires}, 1341637509;
#is $adapter->expires, 'Sat, 07 Jul 2012 05:05:09 GMT';
is $adapter{Date}, time2str( time );
ok $adapter->_date_header_is_fixed;
warning_is { delete $adapter{Date} } 'The Date header is fixed';
warning_is { $adapter{Date} = 'foo' } 'The Date header is fixed';

%adaptee = ( -expires => q{} );
is $adapter{Expires}, q{};
ok !$adapter->_date_header_is_fixed;

%adaptee = ( -nph => 1 );
is $adapter{Date}, time2str( time );
ok $adapter->_date_header_is_fixed;

%adaptee = ( -nph => 0 );
is $adapter{Date}, undef;
ok !$adapter->_date_header_is_fixed;

%adaptee = ( -cookie => 1 );
is $adapter{Date}, time2str( time );
ok $adapter->_date_header_is_fixed;

%adaptee = ( -cookie => q{} );
is $adapter{Date}, undef;
ok !$adapter->_date_header_is_fixed;

%adaptee = ();
$adapter{Date} = 'Sat, 07 Jul 2012 05:05:09 GMT';
is $adaptee{-date}, 'Sat, 07 Jul 2012 05:05:09 GMT';
is $adapter{Date}, 'Sat, 07 Jul 2012 05:05:09 GMT';

%adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
$adapter->nph( 1 );
is_deeply \%adaptee, { -nph => 1 };

%adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
$adapter{Expires} = '+3M';
is_deeply \%adaptee, { -expires => '+3M' };

%adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
$adapter{Set_Cookie} = 'ID=123456; path=/';
is_deeply \%adaptee, { -cookie => 'ID=123456; path=/' };
