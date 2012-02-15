package Blosxom::Header::Object;
use strict;
use warnings;

sub new {
    my ( $class, %header ) = @_;
    bless \%header, $class;
}

sub get {
    my ( $self, $key ) = @_;
    $self->{get}->( $key );
}

sub set {
    my ( $self, $key, $value ) = @_;
    $self->{set}->( $key => $value );
}

sub has {
    my ( $self, $key ) = @_;
    $self->{has}->( $key );
}

sub remove {
    my ( $self, $key ) = @_;
    $self->{remove}->( $key );
}

1;

__END__

=head1 NAME

Blosxom::Header::Object - OO interface of Blosxom::Header

=head1 SYNOPSIS

  package Blosxom::Header;

  sub new {
      require Blosxom::Header::Object;
      my $header_ref = $_[1];

      Blosxom::Header::Object->new(
          get    => sub { get_header( $header_ref, @_ )    },
          set    => sub { set_header( $header_ref, @_ )    },
          has    => sub { has_header( $header_ref, @_ )    },
          remove => sub { remove_header( $header_ref, @_ ) },
      );
  }

=head1 DESCRIPTION

Wraps get_header, set_header, has_header and remove_header in an object.

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
