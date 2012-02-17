package Blosxom::Header::Object;
use strict;
use warnings;
use Blosxom::Header qw(:all);
use Scalar::Util qw(refaddr);

my %header_of;

sub new {
    my $class      = shift;
    my $header_ref = shift;
    my $self       = bless \do { my $anon_scalar }, $class;
    my $id         = refaddr( $self );

    $header_of{ $id } = $header_ref;

    return $self;
}

sub get {
    my $self = shift;
    my $key  = shift;
    my $id   = refaddr( $self );

    return get_header( $header_of{ $id }, $key );
}

sub set {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    my $id    = refaddr( $self );

    set_header( $header_of{ $id }, $key => $value );

    return;
}

sub exists {
    my $self = shift;
    my $key  = shift;
    my $id   = refaddr( $self );

    return exists_header( $header_of{ $id }, $key );
}

sub delete {
    my $self = shift;
    my $key  = shift;
    my $id   = refaddr( $self );

    delete_header( $header_of{ $id }, $key );

    return;
}

sub DESTROY {
    my $self = shift;
    my $id   = refaddr( $self );

    delete $header_of{ $id };

    return;
}

1;

__END__

=head1 NAME

Blosxom::Header::Object - Wraps subroutines exported by Blosxom::Header in an object

=head1 SYNOPSIS

  use Blosxom::Header::Object;

  my $h     = Blosxom::Header::Object->new( $blosxom::header );
  my $value = $h->get( 'foo' );
  my $bool  = $h->exists( 'foo' );
  $h->set( 'foo' => 'bar' );
  $h->remove( 'foo' );

=head1 DESCRIPTION

Wraps subroutines exported by Blosxom::Header in an object.

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ryo Anazawa. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
