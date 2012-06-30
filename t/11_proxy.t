use strict;
use Blosxom::Header::Proxy;
use Test::Exception;
use Test::More tests => 15;

{
    package blosxom;
    our $header;
}

my $proxy = tie my %proxy => 'Blosxom::Header::Proxy';
isa_ok $proxy, 'Blosxom::Header::Proxy';
can_ok $proxy, qw(
    FETCH STORE DELETE EXISTS CLEAR FIRSTKEY NEXTKEY
    is_initialized header content_type content_disposition
    attachment nph
);

our $Header;
*Header = \$blosxom::header;

subtest 'SCALAR()' => sub {
    $Header = { -type => q{} };
    ok !%proxy;

    $Header = { -type => q{}, -charset => 'utf-8' };
    ok !%proxy;

    $Header = { -type => q{}, -foo => q{} };
    ok !%proxy;

    $Header = { -type => q{}, -foo => 'bar' };
    ok %proxy;

    $Header = {};
    ok %proxy;

    $Header = { -foo => 'bar' };
    ok %proxy;
};

subtest 'CLEAR()' => sub {
    $Header = { -foo => 'bar' };
    %proxy = ();
    is_deeply $Header, { -type => q{} };
};

subtest 'EXISTS()' => sub {
    $Header = { -foo => 'bar', -bar => q{} };
    ok exists $proxy{Foo};
    ok !exists $proxy{Bar};
    ok !exists $proxy{Baz};

    $Header = { -type => q{} };
    ok !exists $proxy{Content_Type};

    $Header = {};
    ok exists $proxy{Content_Type};

    $Header = { -type => 'foo' };
    ok exists $proxy{Content_Type};

    $Header = { -type => undef };
    ok exists $proxy{Content_Type};

    $Header = { -attachment => 'foo' };
    ok exists $proxy{Content_Disposition};

    $Header = { -attachment => q{} };
    ok !exists $proxy{Content_Disposition};

    $Header = { -attachment => undef };
    ok !exists $proxy{Content_Disposition};

    $Header = {};
    ok !exists $proxy{Content_Disposition};
};

subtest 'DELETE()' => sub {
    $Header = { -foo => 'bar', -bar => 'baz' };
    is delete $proxy{Foo}, 'bar';
    is_deeply $Header, { -bar => 'baz' };

    $Header = {};
    is delete $proxy{Content_Type}, 'text/html; charset=ISO-8859-1';
    is_deeply $Header, { -type => q{} };

    $Header = { -type => q{} };
    is delete $proxy{Content_Type}, undef;
    is_deeply $Header, { -type => q{} };

    $Header = { -type => 'text/plain', -charset => 'utf-8' };
    is delete $proxy{Content_Type}, 'text/plain; charset=utf-8';
    is_deeply $Header, { -type => q{} };

    $Header = { -attachment => 'foo' };
    is delete $proxy{Content_Disposition}, 'attachment; filename="foo"';
    is_deeply $Header, {};

    $Header = { -content_disposition => 'inline' };
    is delete $proxy{Content_Disposition}, 'inline';
    is_deeply $Header, {};
};

subtest 'FETCH()' => sub {
    $Header = { -foo => 'bar' };
    is $proxy{Foo}, 'bar';
    is $proxy{Bar}, undef;
    is $proxy{Content_Type}, 'text/html; charset=ISO-8859-1';

    $Header = { -attachment => 'genome.jpg' };
    is $proxy{Content_Disposition}, 'attachment; filename="genome.jpg"';
};

subtest 'STORE()' => sub {
    $Header = {};
    $proxy{Foo} = 'bar';
    is_deeply $Header, { -foo => 'bar' };
    
    $Header = { -attachment => 'foo' };
    $proxy{Content_Disposition} = 'inline';
    is_deeply $Header, { -content_disposition => 'inline' };
    
    $Header = { -charset => 'euc-jp' };
    $proxy{Content_Type} = 'text/plain; charset=utf-8';
    is_deeply $Header, { -type => 'text/plain; charset=utf-8' };
};

subtest 'each()' => sub {
    $Header = {};
    is each %proxy, 'Content-Type';
    is each %proxy, undef;

    $Header = { -type => q{} };
    is each %proxy, undef;

    $Header = { -charset => 'foo', -nph => 1 };
    is each %proxy, 'Content-Type';
    is each %proxy, undef;

    $Header = { -type => q{}, -charset => 'foo', -nph => 1 };
    is each %proxy, undef;

    $Header = { -foo => 'bar' };
    is each %proxy, 'Content-Type';
    is each %proxy, 'Foo';
    is each %proxy, undef;

    $Header = {
        -nph        => 'foo',
        -charset    => 'foo',
        -status     => 'foo',
        -target     => 'foo',
        -p3p        => 'foo',
        -cookie     => 'foo',
        -expires    => 'foo',
        -attachment => 'foo',
        -foo_bar    => 'foo',
        -foo        => q{},
        -bar        => q{},
        -baz        => q{},
        -qux        => q{},
    };

    my @got = sort keys %proxy;

    my @expected = qw(
        Content-Disposition
        Content-Type
        Expires
        Foo-bar
        P3P
        Set-Cookie
        Status
        Window-Target
    );

    is_deeply \@got, \@expected;
};

subtest 'is_initialized()' => sub {
    undef $Header;
    ok !$proxy->is_initialized, 'should return false';

    $Header = {};
    ok $proxy->is_initialized, 'should return true';
};

subtest 'header()' => sub {
    undef $Header;
    my $expected = qr/\$blosxom::header hasn't been initialized yet/; 
    throws_ok { $proxy->header } $expected;

    $Header = {};
    is $proxy->header, $Header;
};

subtest 'content_type()' => sub {
    $Header = {};
    is $proxy->content_type, 'text/html; charset=ISO-8859-1';

    $Header = { -type => 'text/plain' };
    is $proxy->content_type, 'text/plain; charset=ISO-8859-1';

    $Header = { -charset => 'utf-8' };
    is $proxy->content_type, 'text/html; charset=utf-8';

    $Header = { -type => 'text/plain', -charset => 'utf-8' };
    is $proxy->content_type, 'text/plain; charset=utf-8';

    $Header = { -type => q{} };
    is $proxy->content_type, undef;

    $Header = { -type => q{}, -charset => 'utf-8' };
    is $proxy->content_type, undef;

    $Header = { -type => 'text/plain; charset=EUC-JP' };
    is $proxy->content_type, 'text/plain; charset=EUC-JP';

    $Header = {
        -type    => 'text/plain; charset=euc-jp',
        -charset => 'utf-8',
    };
    is $proxy->content_type, 'text/plain; charset=euc-jp';

    $Header = { -charset => q{} };
    is $proxy->content_type, 'text/html';

    $Header = {};
    $proxy->content_type( 'text/plain; charset=utf-8' );
    is_deeply $Header, { -type => 'text/plain; charset=utf-8' };

    $Header = {};
    $proxy->content_type( 'text/plain' );
    is_deeply $Header, { -type => 'text/plain', -charset => q{} };

    #$Header = {};
    #$proxy->content_type( undef );
    #is_deeply $Header, { -type => q{} };
};

subtest 'attachment()' => sub {
    $Header = {};
    is $proxy->attachment, undef;
    $proxy->attachment( 'genome.jpg' );
    is $proxy->attachment, 'genome.jpg';
    is $proxy->header->{-attachment}, 'genome.jpg';
};

subtest 'nph()' => sub {
    $Header = {};
    ok !$proxy->nph;
    $proxy->nph( 1 );
    ok $proxy->nph;
    is $proxy->header->{-nph}, 1;
};

subtest 'content_disposition()' => sub {
    $Header = { -attachment => 'genome.jpg' };
    is $proxy->content_disposition, 'attachment; filename="genome.jpg"';

    $Header = { -content_disposition => 'inline' };
    is $proxy->content_disposition, 'inline';
};
