use strict;
use warnings;
use Blosxom::Header;
use Test::More tests => 31;

my %adaptee;
my $adapter = tie my %adapter, 'Blosxom::Header', \%adaptee;

%adaptee = ( -type => q{} );
is $adapter{Content_Type}, undef;
ok !exists $adapter{Content_Type};
ok !%adapter;
is delete $adapter{Content_Type}, undef;
is_deeply \%adaptee, { -type => q{} };

%adaptee = ();
is $adapter{Content_Type}, 'text/html; charset=ISO-8859-1';
ok exists $adapter{Content_Type};
ok %adapter;
is delete $adapter{Content_Type}, 'text/html; charset=ISO-8859-1';
is_deeply \%adaptee, { -type => q{} };

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
ok %adapter;

%adaptee = ( -type => undef, -charset => 'utf-8' );
is $adapter{Content_Type}, 'text/html; charset=utf-8';

%adaptee = ( -type => 'text/plain', -charset => 'utf-8' );
is delete $adapter{Content_Type}, 'text/plain; charset=utf-8';
is_deeply \%adaptee, { -type => q{} };

%adaptee = ();
$adapter{Content_Type} = 'text/html; charSet=utf-8';
is_deeply \%adaptee, { -type => 'text/html; charset=utf-8' };

# feature
%adaptee = ( -type => 'text/plain; charSet=utf-8' );
is $adapter{Content_Type}, 'text/plain; charSet=utf-8; charset=ISO-8859-1';

subtest 'charset()' => sub {
    %adaptee = ();
    is $adapter->charset, 'ISO-8859-1';

    %adaptee = ( -charset => q{} );
    is $adapter->charset, undef;

    %adaptee = ( -type => q{} );
    is $adapter->charset, undef;

    %adaptee = ( -type => 'text/html; charset=euc-jp' );
    is $adapter->charset, 'EUC-JP';

    %adaptee = ( -type => 'text/html; charset=iso-8859-1; Foo=1' );
    is $adapter->charset, 'ISO-8859-1';

    %adaptee = ( -type => 'text/html; charset="iso-8859-1"; Foo=1' );
    is $adapter->charset, 'ISO-8859-1';

    %adaptee = ( -type => 'text/html; charset = "iso-8859-1"; Foo=1' );
    is $adapter->charset, 'ISO-8859-1';

    %adaptee = ( -type => 'text/html;\r\n charset = "iso-8859-1"; Foo=1' );
    is $adapter->charset, 'ISO-8859-1';

    %adaptee = ( -type => 'text/html;\r\n charset = iso-8859-1 ; Foo=1' );
    is $adapter->charset, 'ISO-8859-1';

    %adaptee = ( -type => 'text/html;\r\n charset = iso-8859-1 ' );
    is $adapter->charset, 'ISO-8859-1';
};

subtest 'content_type()' => sub {
    %adaptee = ();
    is $adapter->content_type, 'text/html';
    my @got = $adapter->content_type;
    my @expected = ( 'text/html', 'charset=ISO-8859-1' );
    is_deeply \@got, \@expected;

    %adaptee = ( -type => 'text/plain; charset=EUC-JP; Foo=1' );
    is $adapter->content_type, 'text/plain';
    @got = $adapter->content_type;
    @expected = ( 'text/plain', 'charset=EUC-JP; Foo=1' );
    is_deeply \@got, \@expected;

    %adaptee = ();
    $adapter->content_type( 'text/plain; charset=EUC-JP' );
    is_deeply \%adaptee, { -type => 'text/plain; charset=EUC-JP' };

    %adaptee = ( -type => 'text/plain; Foo=1', -charset => 'utf-8' );
    @got = $adapter->content_type;
    @expected = ( 'text/plain', 'Foo=1; charset=utf-8' );
    is_deeply \@got, \@expected;

    %adaptee = ( -type => q{} );
    is $adapter->content_type, q{};

    %adaptee = ( -type => '   TEXT  / HTML   ' );
    is $adapter->content_type, 'text/html';
};
