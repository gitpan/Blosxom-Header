use strict;
use Blosxom::Header::Proxy;
use Test::Exception;
use Test::More tests => 10;

{
    package blosxom;
    our $header;
}

my $proxy = tie my %proxy => 'Blosxom::Header::Proxy';
isa_ok $proxy, 'Blosxom::Header::Proxy';
can_ok $proxy, qw(
    FETCH STORE DELETE EXISTS CLEAR FIRSTKEY NEXTKEY SCALAR
    is_initialized
);

our $Header;
*Header = \$blosxom::header;

subtest 'is_initialized()' => sub {
    undef $Header;
    ok !$proxy->is_initialized, 'should return false';

    $Header = {};
    ok $proxy->is_initialized, 'should return true';
};

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
    $Header = { -foo => 'bar' };
    ok exists $proxy{Foo};
    ok !exists $proxy{Bar};

    $Header = { -type => q{} };
    ok !exists $proxy{Content_Type};
    ok exists $proxy{-type};

    $Header = {};
    ok exists $proxy{Content_Type};
    ok !exists $proxy{-type};

    $Header = { -type => 'foo' };
    ok exists $proxy{Content_Type};
    ok exists $proxy{-type};

    $Header = { -type => undef };
    ok exists $proxy{Content_Type};
    ok exists $proxy{-type};

    $Header = { -attachment => 'foo' };
    ok exists $proxy{Content_Disposition};
    ok exists $proxy{-attachment};

    $Header = { -attachment => q{} };
    ok !exists $proxy{Content_Disposition};
    ok exists $proxy{-attachment};

    $Header = { -attachment => undef };
    ok !exists $proxy{Content_Disposition};
    ok exists $proxy{-attachment};
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

    $Header = { -attachment => 'foo' };
    is delete $proxy{-attachment}, 'foo';
    is_deeply $Header, {};
};

subtest 'FETCH()' => sub {
    $Header = {};
    is $proxy{Content_Type}, 'text/html; charset=ISO-8859-1';
    is $proxy{-type}, undef;
    is $proxy{-charset}, undef;

    $Header = { -type => 'text/plain' };
    is $proxy{Content_Type}, 'text/plain; charset=ISO-8859-1';
    is $proxy{-type}, 'text/plain';
    is $proxy{-charset}, undef;

    $Header = { -charset => 'utf-8' };
    is $proxy{Content_Type}, 'text/html; charset=utf-8';
    is $proxy{-type}, undef;
    is $proxy{-charset}, 'utf-8';

    $Header = { -type => 'text/plain', -charset => 'utf-8' };
    is $proxy{Content_Type}, 'text/plain; charset=utf-8';
    is $proxy{-type}, 'text/plain';
    is $proxy{-charset}, 'utf-8';

    $Header = { -type => q{} };
    is $proxy{Content_Type}, undef;
    is $proxy{-type}, q{};
    is $proxy{-charset}, undef;

    $Header = { -type => q{}, -charset => 'utf-8' };
    is $proxy{Content_Type}, undef;
    is $proxy{-type}, q{};
    is $proxy{-charset}, 'utf-8';

    $Header = { -type => 'text/plain; charset=EUC-JP' };
    is $proxy{Content_Type}, 'text/plain; charset=EUC-JP';
    is $proxy{-type}, 'text/plain; charset=EUC-JP';
    is $proxy{-charset}, undef;

    $Header = {
        -type    => 'text/plain; charset=euc-jp',
        -charset => 'utf-8',
    };
    is $proxy{Content_Type}, 'text/plain; charset=euc-jp';
    is $proxy{-type}, 'text/plain; charset=euc-jp';
    is $proxy{-charset}, 'utf-8';

    $Header = { -charset => q{} };
    is $proxy{Content_Type}, 'text/html';
    is $proxy{-type}, undef;
    is $proxy{-charset}, q{};

    $Header = { -attachment => 'foo' };
    is $proxy{Content_Disposition}, 'attachment; filename="foo"';
    is $proxy{-attachment}, 'foo';
};

subtest 'STORE()' => sub {
    $Header = {};
    $proxy{Foo} = 'bar';
    is_deeply $Header, { -foo => 'bar' };
    
    $Header = { -attachment => 'foo' };
    $proxy{Content_Disposition} = 'inline';
    is_deeply $Header, { -content_disposition => 'inline' };
    
    $Header = { -content_disposition => 'inline' };
    $proxy{-attachment} = 'genome.jpg';
    is_deeply $Header, { -attachment => 'genome.jpg' };

    $Header = { -charset => 'euc-jp' };
    $proxy{Content_Type} = 'text/plain; charset=utf-8';
    is_deeply $Header, { -type => 'text/plain; charset=utf-8' };

    $Header = { -charset => 'euc-jp' };
    $proxy{Content_Type} = 'text/plain';
    is_deeply $Header, { -type => 'text/plain', -charset => q{} };

    $Header = { -charset => 'euc-jp' };
    $proxy{-type} = 'text/plain; charset=utf-8';
    is_deeply $Header, {
        -type    => 'text/plain; charset=utf-8',
        -charset => 'euc-jp',
    };

    $Header = { -charset => 'euc-jp' };
    $proxy{-type} = 'text/plain';
    is_deeply $Header, { -type => 'text/plain', -charset => 'euc-jp' };
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
    is each %proxy, 'Foo';
    is each %proxy, 'Content-Type';
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
