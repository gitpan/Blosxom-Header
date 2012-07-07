use strict;
use Blosxom::Header::Adapter;
use Test::More tests => 25;

my %adaptee;
tie my %adapter, 'Blosxom::Header::Adapter', \%adaptee;

%adaptee = ( -type => q{} );
is $adapter{Content_Type}, undef;
ok !exists $adapter{Content_Type};
ok !%adapter;

%adaptee = ();
is $adapter{Content_Type}, 'text/html; charset=ISO-8859-1';
ok exists $adapter{Content_Type};
ok %adapter;

%adaptee = ( -type => 'text/plain' );
is $adapter{Content_Type}, 'text/plain; charset=ISO-8859-1';
ok exists $adapter{Content_Type};

%adaptee = ( -charset => 'utf-8' );
is $adapter{Content_Type}, 'text/html; charset=utf-8';

%adaptee = ( -type => 'text/plain', -charset => 'utf-8' );
is $adapter{Content_Type}, 'text/plain; charset=utf-8';

%adaptee = ( -type => q{}, -charset => 'utf-8' );
is $adapter{Content_Type}, undef;

%adaptee = ( -type => 'text/plain; charset=EUC-JP' );
is $adapter{Content_Type}, 'text/plain; charset=EUC-JP';

%adaptee = (
    -type    => 'text/plain; charset=euc-jp',
    -charset => 'utf-8',
);
is $adapter{Content_Type}, 'text/plain; charset=euc-jp';

%adaptee = ( -charset => q{} );
is $adapter{Content_Type}, 'text/html';

%adaptee = ();
$adapter{Content_Type} = 'text/plain; charset=utf-8';
is_deeply \%adaptee, { -type => 'text/plain; charset=utf-8' };

%adaptee = ();
$adapter{Content_Type} = 'text/plain';
is_deeply \%adaptee, { -type => 'text/plain', -charset => q{} };

%adaptee = ( -charset => 'euc-jp' );
$adapter{Content_Type} = 'text/plain; charset=utf-8';
is_deeply \%adaptee, { -type => 'text/plain; charset=utf-8' };

%adaptee = ( -type => undef );
is $adapter{Content_Type}, 'text/html; charset=ISO-8859-1';
ok exists $adapter{Content_Type};

#%{ adaptee } = ();
#undef $adapter{Content_Type};
#is_deeply adaptee, { -type => q{} };

%adaptee = ();
is delete $adapter{Content_Type}, 'text/html; charset=ISO-8859-1';
is_deeply \%adaptee, { -type => q{} };

%adaptee = ( -type => q{} );
is delete $adapter{Content_Type}, undef;
is_deeply \%adaptee, { -type => q{} };

%adaptee = ( -type => 'text/plain', -charset => 'utf-8' );
is delete $adapter{Content_Type}, 'text/plain; charset=utf-8';
is_deeply \%adaptee, { -type => q{} };
