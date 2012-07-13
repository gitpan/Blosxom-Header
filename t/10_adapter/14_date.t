use strict;
use Blosxom::Header::Adapter;
use HTTP::Date;
use Test::More tests => 17;
use Test::Warn;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header::Adapter', \%adaptee;

%adaptee = ( -expires => 1341637509 );
is $adapter{Expires}, 'Sat, 07 Jul 2012 05:05:09 GMT';
is $adapter{Date}, time2str( time );
ok $adapter->has_date_header;
warning_is { delete $adapter{Date} } 'The Date header is fixed';
warning_is { $adapter{Date} = 'foo' } 'The Date header is fixed';

%adaptee = ( -expires => q{} );
is $adapter{Expires}, undef;
ok !$adapter->has_date_header;

%adaptee = ( -nph => 1 );
is $adapter{Date}, time2str( time );
ok $adapter->has_date_header;

%adaptee = ( -nph => 0 );
is $adapter{Date}, undef;
ok !$adapter->has_date_header;

%adaptee = ( -cookie => 1 );
is $adapter{Date}, time2str( time );
ok $adapter->has_date_header;

%adaptee = ( -cookie => q{} );
is $adapter{Date}, undef;
ok !$adapter->has_date_header;

%adaptee = ();
$adapter{Date} = 'Sat, 07 Jul 2012 05:05:09 GMT';
is $adaptee{-date}, 'Sat, 07 Jul 2012 05:05:09 GMT';
is $adapter{Date}, 'Sat, 07 Jul 2012 05:05:09 GMT';
