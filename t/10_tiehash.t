use strict;
use Blosxom::Header;
use Test::More;

{
    package blosxom;
    our $header;
}

eval { tie my %header, 'Blosxom::Header' };
#like $@, qr{^\$blosxom::header hasn't been initialized yet};
like $@, qr{^Not a HASH reference};

# Initialize
$blosxom::header = {
    -foo => 'bar',
    -bar => 'baz',
};

{
    tie my %header, 'Blosxom::Header';

    ok exists $header{-foo},  'EXISTS() returns true';
    ok !exists $header{-baz}, 'EXISTS() returns false';
    ok exists $header{Foo},   'EXISTS(), not case-sensitive';

    is $header{-foo}, 'bar', 'FETCH()';
    is $header{-baz}, undef, 'FETCH() undef';
    is $header{Foo}, 'bar',  'FETCH(), not case-sensitive';

    is_deeply [ sort keys %header ], [qw/-bar -foo/], 'keys';

    eval { $header{bar} = 'baz' };
    like $@, qr{^Modification of a read-only value attempted};

    eval { delete $header{foo} };
    like $@, qr{^Modification of a read-only value attempted};

    eval { %header = () };
    like $@, qr{^Modification of a read-only value attempted};

    eval { untie %header };
    like $@, qr{^Modification of a read-only value attempted};
}

{
    tie my %header, 'Blosxom::Header', 'rw';

    %header = ();
    is_deeply $blosxom::header, {}, 'CLEAR()';

    $header{-foo} = 'bar';
    is $blosxom::header->{-foo}, 'bar', 'STORE()';

    $header{Foo} = 'baz';
    is $blosxom::header->{-foo}, 'baz', 'STORE(), not case-sensitive';

    %header = (
        -foo => 'bar',
        -bar => 'baz',
        -baz => 'qux',
    );

    is delete $header{-foo}, 'bar', 'DELETE()';
    is delete $header{-foo}, undef, 'DELETE() nothing';
    is delete $header{Bar}, 'baz',  'DELETE(), not case-sensitive';
    is_deeply $blosxom::header, { -baz => 'qux' };
}

{  # just for fun
    my %default = (
        -type    => 'text/plain',
        -charset => 'utf-8',
    );

    tie my %header => 'Blosxom::Header', # isa
        'rw',      # is
        \%default; # default

    is $header{type}, 'text/plain';
}

done_testing;
