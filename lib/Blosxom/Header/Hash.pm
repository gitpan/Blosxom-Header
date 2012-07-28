package Blosxom::Header::Hash;
use strict;
use warnings;
use overload '%{}' => 'as_hashref', 'fallback' => 1;
use Blosxom::Header::Adapter;
use Blosxom::Header::Util qw/str2time/;
use Carp qw/croak/;
use Scalar::Util qw/refaddr/;

my %header_of;
my %adapter_of;
my %iterator_of; # deprecated

sub new {
    my $self   = bless \do { my $anon_scalar }, shift;
    my $header = shift;
    my $id     = refaddr $self;

    my $adapter = tie my %header, 'Blosxom::Header::Adapter', $header;

    $adapter_of{$id}  = $adapter;
    $header_of{$id}   = \%header;
    $iterator_of{$id} = {};

    $self;
}

sub as_hashref {
    my $self = shift;
    my $id = refaddr $self;
    $header_of{ $id };
}

sub get {
    my ( $self, @fields ) = @_;
    my $id = refaddr $self;
    @{ $header_of{$id} }{ @fields };
}

sub set {
    my ( $self, %header ) = @_;
    my $id = refaddr $self;
    @{ $header_of{$id} }{ keys %header } = values %header; # merge!
    return;
}

sub delete {
    my ( $self, @fields ) = @_;
    my $id = refaddr $self;
    delete @{ $header_of{$id} }{ @fields };
}

sub exists {
    my ( $self, $field ) = @_;
    my $id = refaddr $self;
    exists $header_of{$id}->{$field};
}

sub clear {
    my $self = shift; 
    my $id = refaddr $self;
    %{ $header_of{$id} } = ();
}

sub each {
    my $self     = shift;
    my $callback = shift;
    my $id       = refaddr $self;

    if ( ref $callback eq 'CODE' ) {
        for my $field ( $adapter_of{$id}->field_names ) {
            $callback->( $field, $header_of{$id}->{$field} );
        }
    }
    elsif ( defined wantarray ) { # deprecated
        return $self->_each;
    }
    else {
        croak( 'Must provide a code reference to each()' );
    }

    return;
}

# This method is deprecated and will be remove in 0.06
sub _each {
    my $self = shift;
    my $id   = refaddr $self;
    my $iter = $iterator_of{$id};

    if ( !%{ $iter } or $iter->{is_exhausted} ) {
        my @fields = $adapter_of{$id}->field_names;
        %{ $iter } = (
            collection   => \@fields,
            size         => scalar @fields,
            current      => 0,
            is_exhausted => 0,
        );
    }

    if ( $iter->{current} < $iter->{size} ) {
        my $field = $iter->{collection}->[ $iter->{current}++ ];
        return wantarray ? ( $field, $header_of{$id}->{$field} ) : $field;
    }
    else {
        $iter->{is_exhausted}++;
    }

    return;
}

sub is_empty {
    my $self = shift;
    my $id = refaddr $self;
    not %{ $header_of{$id} };
}

sub flatten {
    my $self = shift;
    my $id = refaddr $self;
    map { $_, $header_of{$id}->{$_} } $adapter_of{$id}->field_names;
}

sub expires {
    my $self = shift;
    my $id   = refaddr $self;

    if ( @_ ) {
        $header_of{$id}->{Expires} = shift;
    }
    elsif ( my $expires = $adapter_of{$id}->expires ) {
        return str2time( $expires );
    }

    return;
}

sub field_names   { $adapter_of{ refaddr shift }->field_names         }
sub attachment    { $adapter_of{ refaddr shift }->attachment( @_ )    }
sub nph           { $adapter_of{ refaddr shift }->nph( @_ )           }
sub p3p_tags      { $adapter_of{ refaddr shift }->p3p_tags( @_ )      }
sub push_p3p_tags { $adapter_of{ refaddr shift }->push_p3p_tags( @_ ) }

sub DESTROY {
    my $self = shift;
    my $id = refaddr $self;
    delete $header_of{$id};
    delete $adapter_of{$id};
    delete $iterator_of{$id};
}

1;

__END__

=head1 NAME

Blosxom::Header::Hash - Base class for Blosxom::Header

=head1 DESCRIPTION

This class is the base class for L<Blosxom::Header>,
it is not used directly by callers.

=head1 SEE ALSO

L<Blosxom::Header>

=head1 MAINTAINER

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

