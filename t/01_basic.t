use strict;
use Test::More;
use Blosxom::Header;
use Blosxom::Header::Prototype;

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

{
    my $counter = 0;
    my %method  = ( count => sub { $counter++ } );
    my $object  = Blosxom::Header::Prototype->new( %method );
    isa_ok $object, 'Blosxom::Header::Prototype';
    can_ok $object, qw(count);

    $object->count;

    is $counter, 1;
    ok !$object->can('foo');
}

done_testing;
