use strict;
use Blosxom::Header::Adapter;
use Test::More tests => 17;

my %adaptee;
tie my %adapter, 'Blosxom::Header::Adapter', \%adaptee;

%adaptee = ();
is each %adapter, 'Content-Type';
is each %adapter, undef;

%adaptee = ( -type => q{} );
is each %adapter, undef;

%adaptee = ( -charset => 'foo', -nph => 1 );
is each %adapter, 'Date';
is each %adapter, 'Content-Type';
is each %adapter, undef;

%adaptee = ( -type => q{}, -charset => 'foo', -nph => 1 );
is each %adapter, 'Date';
is each %adapter, undef;

%adaptee = ( -foo => 'bar' );
is each %adapter, 'Foo';
is each %adapter, 'Content-Type';
is each %adapter, undef;

%adaptee = ( -foo => 'bar' );
while ( my $key = each %adapter ) { delete $adapter{ $key } }
is_deeply \%adaptee, { -type => q{} };

%adaptee = ();
for ( values %adapter ) { tr/A-Z/a-z/ }
is_deeply \%adaptee, { -type => 'text/html; charset=iso-8859-1' };

# feature
%adaptee = ( -foo => 'bar' );
is each %adapter, 'Foo';
my %copy = %adapter;
is each %adapter, 'Foo';
is each %adapter, 'Content-Type';
is each %adapter, undef;

# [bug] Date shouldn't appear
#%adaptee = ( -expires => 'now' );
#my @got;
#while ( my $field = each %adapter ) {
#    push @got, $field;
#    delete $adapter{ $field };
#}
#is_deeply \@got, [qw/Expires Date Content-Type/];

