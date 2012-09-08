use strict;
use Blosxom::Header;
use HTTP::Date;
use Test::More tests => 13;
use Test::Warn;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header', \%adaptee;

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

%adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
$adapter->nph( 1 );
is_deeply \%adaptee, { -nph => 1 };

%adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
$adapter{Set_Cookie} = 'ID=123456; path=/';
is_deeply \%adaptee, { -cookie => 'ID=123456; path=/' };

subtest 'Date' => sub {
    %adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
    ok exists $adapter{Date};

    %adaptee = ();
    $adapter{Date} = 'Sat, 07 Jul 2012 05:05:09 GMT';
    is $adaptee{-date}, 'Sat, 07 Jul 2012 05:05:09 GMT';
    is $adapter{Date}, 'Sat, 07 Jul 2012 05:05:09 GMT';

    %adaptee = ();
    is $adapter->date, undef;

    my $now = 1341637509;
    $adapter->date( $now );
    is $adapter->date, $now;
    is $adaptee{-date}, 'Sat, 07 Jul 2012 05:05:09 GMT';
};

subtest 'last_modified()' => sub {
    %adaptee = ();
    is $adapter->last_modified, undef;

    my $now = 1341637509;
    $adapter->last_modified( $now );
    is $adapter->last_modified, $now;
    is $adaptee{-last_modified}, 'Sat, 07 Jul 2012 05:05:09 GMT';
};

subtest 'Expires' => sub {
    %adaptee = ( -expires => 1341637509 );
    is $adapter{Expires}, 1341637509;
    #is $adapter->expires, 'Sat, 07 Jul 2012 05:05:09 GMT';
    is $adapter{Date}, time2str( time );
    ok $adapter->_date_header_is_fixed;
    warning_is { delete $adapter{Date} } 'The Date header is fixed';
    warning_is { $adapter{Date} = 'foo' } 'The Date header is fixed';

    %adaptee = ( -date => 'Sat, 07 Jul 2012 05:05:09 GMT' );
    $adapter{Expires} = '+3M';
    is_deeply \%adaptee, { -expires => '+3M' };

    %adaptee = ( -expires => q{} );
    is $adapter{Expires}, q{};
    ok !$adapter->_date_header_is_fixed;

    %adaptee = ();
    is $adapter->expires, undef;

    my $now = 1341637509;
    $adapter->expires( $now );
    is $adapter->expires, $now, 'get expires()';
    is $adaptee{-expires}, $now;

    $now++;
    $adapter->expires( 'Sat, 07 Jul 2012 05:05:10 GMT' );
    is $adapter->expires, $now, 'get expires()';
    is $adaptee{-expires}, 'Sat, 07 Jul 2012 05:05:10 GMT';
};
