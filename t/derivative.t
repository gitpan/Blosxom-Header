use strict;
use warnings;
use Test::More tests => 1;

package CGI::Header;
use base 'Blosxom::Header';
use Carp qw/carp/;
use Scalar::Util qw/refaddr/;

sub header_get    { carp 'not supported' }
sub header_set    { carp 'not supported' }
sub header_exists { carp 'not supported' }
sub header_delete { carp 'not supported' }
sub header_iter   { carp 'not supported' }

my %header_of;

sub new {
    my $class = shift;
    my $self = tie my %header, $class, shift;
    $header_of{ refaddr $self } = \%header;
    $self;
}

sub instance       { carp 'not supported' }
sub has_instance   { carp 'not supported' }
sub is_initialized { carp 'not supported' }

sub as_hashref { $header_of{ refaddr shift } }

sub UNTIE {
    my $self = shift;
    delete $header_of{ refaddr $self };
    return;
}

sub DESTROY {
    my $self = shift;
    delete $header_of{ refaddr $self };
    $self->SUPER::DESTROY;
}

package main;

my $adaptee = {};
my $adapter = CGI::Header->new( $adaptee );
$adapter->{Foo} = 'bar';
is_deeply $adaptee, { -foo => 'bar' };


