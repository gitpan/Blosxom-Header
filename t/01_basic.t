use strict;
use Test::More;
use Blosxom::Header;

{
    my @tests = (
        [ 'foo'      => 'foo'     ],
        [ 'Foo'      => 'foo'     ],
        [ '-foo'     => 'foo'     ],
        [ '-Foo'     => 'foo'     ],
        [ 'foo_bar'  => 'foo-bar' ],
        [ 'Foo_Bar'  => 'foo-bar' ],
        [ '-foo_bar' => 'foo-bar' ],
        [ '-Foo_Bar' => 'foo-bar' ],
    );

    for my $test ( @tests ) {
        my ( $input, $output ) = @{ $test };
        is Blosxom::Header::_lc( $input ), $output;
    }
}

done_testing;
