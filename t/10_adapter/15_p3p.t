use strict;
use Blosxom::Header;
use Test::More tests => 16;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header', \%adaptee;

%adaptee = ( -p3p => [qw/CAO DSP LAW CURa/] );
is $adapter{P3P}, 'policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"';

%adaptee = ();
$adapter->p3p_tags( 'CAO' );
is_deeply \%adaptee, { -p3p => 'CAO' };
is delete $adapter{P3P}, 'policyref="/w3c/p3p.xml" CP="CAO"';

%adaptee = ();
$adapter->p3p_tags( 'CAO DSP LAW CURa' );
is_deeply \%adaptee, { -p3p => [qw/CAO DSP LAW CURa/] };

%adaptee = ();
$adapter->p3p_tags( qw/CAO DSP LAW CURa/ );
is_deeply \%adaptee, { -p3p => [qw/CAO DSP LAW CURa/] };

%adaptee = ( -p3p => 'CAO' );
is $adapter->p3p_tags, 'CAO';

%adaptee = ( -p3p => [qw/CAO DSP LAW CURa/] );
is $adapter->p3p_tags, 'CAO';
my @got = $adapter->p3p_tags;
my @expected = qw( CAO DSP LAW CURa );
is_deeply \@got, \@expected;

#%adaptee = ( -p3p => [ 'CAO DSP', 'LAW CURa' ] );
#is $adapter->p3p_tags, 'CAO';
@got = $adapter->p3p_tags;
@expected = qw( CAO DSP LAW CURa );
is_deeply \@got, \@expected;

%adaptee = ( -p3p => 'CAO DSP LAW CURa' );
is $adapter->p3p_tags, 'CAO';
@got = $adapter->p3p_tags;
@expected = qw( CAO DSP LAW CURa );

%adaptee = ();
is $adapter->push_p3p_tags( 'foo' ), 1;
is $adaptee{-p3p}, 'foo';
is $adapter->push_p3p_tags( 'bar' ), 2;
is_deeply $adaptee{-p3p}, [ 'foo', 'bar' ];
is $adapter->push_p3p_tags( 'baz' ), 3;
is_deeply $adaptee{-p3p}, [ 'foo', 'bar', 'baz' ];

