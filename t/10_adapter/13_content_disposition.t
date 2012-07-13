use strict;
use Blosxom::Header::Adapter;
use Test::More tests => 18;

my %adaptee;
my $adapter = tie my %adapter => 'Blosxom::Header::Adapter' => \%adaptee;

%adaptee = ( -attachment => 'genome.jpg' );
is $adapter{Content_Disposition}, 'attachment; filename="genome.jpg"';
ok exists $adapter{Content_Disposition};

%adaptee = ( -attachment => q{} );
is $adapter{Content_Disposition}, undef;
ok !exists $adapter{Content_Disposition};

%adaptee = ( -attachment => undef );
is $adapter{Content_Disposition}, undef;
ok !exists $adapter{Content_Disposition};

%adaptee = ();
is $adapter{Content_Disposition}, undef;
ok !exists $adapter{Content_Disposition};

%adaptee = ( -content_disposition => 'inline' );
is $adapter{Content_Disposition}, 'inline';
ok exists $adapter{Content_Disposition};

%adaptee = ( -attachment => 'foo' );
$adapter{Content_Disposition} = 'inline';
is_deeply \%adaptee, { -content_disposition => 'inline' };

%adaptee = ( -attachment => 'foo' );
is delete $adapter{Content_Disposition}, 'attachment; filename="foo"';
is_deeply \%adaptee, {};

%adaptee = ( -content_disposition => 'inline' );
is delete $adapter{Content_Disposition}, 'inline';
is_deeply \%adaptee, {};

%adaptee = ();
is $adapter->attachment, undef;
$adapter->attachment( 'genome.jpg' );
is $adapter->attachment, 'genome.jpg';
is $adaptee{-attachment}, 'genome.jpg';
