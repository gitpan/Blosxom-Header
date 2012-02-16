package Blosxom::Header::Prototype;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(refaddr);

my %prototype_of;

sub can {
    my $self   = shift;
    my $method = shift;
    my $id     = refaddr( $self );

    return exists $prototype_of{ $id }{ $method };
}

sub new {
    my $class  = shift;
    my %method = @_;
    my $self   = bless \do{ my $anon_scalar }, $class;
    my $id     = refaddr( $self ); 

    $prototype_of{ $id } = \%method;

    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my @args = @_;
    my $id   = refaddr( $self ); 

    ( my $method = our $AUTOLOAD ) =~ s{.*::}{}o;

    if ( $self->can( $method ) ) {
        my $code_ref = $prototype_of{ $id }{ $method };
        return $code_ref->( @args );
    }

    croak qq{Can't locate object method "$method" via package } .
          __PACKAGE__;
}

sub DESTROY {
    my $self = shift;
    my $id   = refaddr( $self );
        
    delete $prototype_of{ $id };

    return;
}

1;

__END__

=head1 NAME

Blosxom::Header::Prototype - wraps existent subroutines in an object

=head1 SYNOPSIS

  use Blosxom::Header::Prototype;

  my $object = Blosxom::Header::Prototype->new(
      foo => sub { 'bar' },
      bar => sub { 'baz' },
  );

  $object->foo(); # 'bar'
  $object->bar(); # 'baz'

=head1 DESCRIPTION

Wraps existent subroutines in an object.

=head2 EXPORT

None.

=head2 METHODS

=over 4

=item $object = Blosxom::Header::Prototype->new( %method )

Create a new Blosxom::Header::Prototype object.

  my $object = Blosxom::Header::Prototype->new(
      method1 => $code_ref1,
      method2 => $code_ref2,
  );

=item $object->can( 'foo' )

  Returns a Boolean value telling whether the specified method exists.

=back

=head1 SEE ALSO

L<Object::Prototype>,
L<Plack::Util>::Prototype

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
