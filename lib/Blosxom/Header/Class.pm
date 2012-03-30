package Blosxom::Header::Class;
use strict;
use warnings;
use Blosxom::Header;
use Carp;

sub new {
    my $class = shift;
    my $header_ref = shift || $blosxom::header;
    croak 'Not a HASH reference' unless ref $header_ref eq 'HASH';
    bless { header => $header_ref }, $class;
}

sub get    { Blosxom::Header::get_header( shift->{header}, @_ )    }
sub set    { Blosxom::Header::set_header( shift->{header}, @_ )    }
sub exists { Blosxom::Header::exists_header( shift->{header}, @_ ) }
sub delete { Blosxom::Header::delete_header( shift->{header}, @_ ) }
sub push   { Blosxom::Header::push_header( shift->{header}, @_ )   }

1;

__END__

=head1 NAME

Blosxom::Header::Class - Provides OO interface

=head1 SYNOPSIS

  {
      package blosxom;
      our $header = { -type => 'text/html' };
  }

  require Blosxom::Header::Class;

  my $h     = Blosxom::Header::Class->new;
  my $value = $h->get( 'foo' );
  my $bool  = $h->exists( 'foo' );

  $h->set( foo => 'bar' );
  $h->delete( 'foo' );

  my @cookies = $h->get( 'Set-Cookie' );
  $h->push( 'Set-Cookie', 'foo' );

  $h->{header}; # same reference as $blosxom::header

=head1 DESCRIPTION

Provides OO interface.

=head1 SEE ALSO

L<Blosxom::Header>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2012 Ryo Anazawa. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
