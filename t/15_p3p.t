use strict;
use warnings;
use Blosxom::Header::Adapter;
use Test::More tests => 12;
use Test::Warn;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header::Adapter', \%adaptee;

%adaptee = ( -p3p => [qw/CAO DSP LAW CURa/] );
is $adapter{P3P}, 'policyref="/w3c/p3p.xml", CP="CAO DSP LAW CURa"';
is $adapter->p3p_tags, 'CAO';
is_deeply [ $adapter->p3p_tags ], [qw/CAO DSP LAW CURa/];

%adaptee = ();
$adapter->p3p_tags( 'CAO' );
is $adapter->p3p_tags, 'CAO';
is_deeply \%adaptee, { -p3p => 'CAO' };
is delete $adapter{P3P}, 'policyref="/w3c/p3p.xml", CP="CAO"';

%adaptee = ();
$adapter->p3p_tags( 'CAO DSP LAW CURa' );
is_deeply \%adaptee, { -p3p => 'CAO DSP LAW CURa' };

%adaptee = ();
$adapter->p3p_tags( qw/CAO DSP LAW CURa/ );
is_deeply \%adaptee, { -p3p => [qw/CAO DSP LAW CURa/] };

%adaptee = ( -p3p => 'CAO DSP LAW CURa' );
is $adapter->p3p_tags, 'CAO';
is_deeply [ $adapter->p3p_tags ], [qw/CAO DSP LAW CURa/];

warning_is { $adapter{P3P} = 'CAO DSP LAW CURa' }
    "Can't assign to '-p3p' directly, use accessors instead";

# this method is obsolete and will be removed in 0.07
subtest 'push_p3p_tags()' => sub {
    %adaptee = ();

    is $adapter->push_p3p_tags( 'foo' ), 1;
    is $adaptee{-p3p}, 'foo';

    is $adapter->push_p3p_tags( 'bar' ), 2;
    is_deeply $adaptee{-p3p}, [ 'foo', 'bar' ];

    is $adapter->push_p3p_tags( 'baz' ), 3;
    is_deeply $adaptee{-p3p}, [ 'foo', 'bar', 'baz' ];
};
