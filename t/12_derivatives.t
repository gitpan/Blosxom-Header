use strict;
use Test::More;

{
    package blosxom;
    our $header = { type => 'text/html' };
}

package DerivedHeader;
use base 'Blosxom::Header';

sub _normalize_field_name {
    my $self = shift;
    my $norm = $self->SUPER::_normalize_field_name( shift );
    $norm =~ s/^-//;
    $norm;
}

package main;

my $header = DerivedHeader->instance;
is $header->type, 'text/html';

done_testing;
