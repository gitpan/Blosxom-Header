package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use Carp;

our $VERSION = '0.03000';

sub new {
    my $class = shift;
    my $header = shift || $blosxom::header;
    croak 'Not a HASH reference' unless ref $header eq 'HASH';
    bless { header => $header }, $class;
}

sub get {
    my ( $self, $field ) = @_;
    return unless $self->exists( $field );
    my $value = $self->{header}->{ _normalize_field_name( $field ) };
    return $value unless ref $value eq 'ARRAY';
    return @{ $value } if wantarray;
    $value->[0];
}

sub delete {
    my $header = shift->{header};
    my $field  = _normalize_field_name( shift );

    delete $header->{ $field };

    return;
}

sub set {
    my $header = shift->{header};
    my $field  = _normalize_field_name( shift );
    my $value  = shift;

    if ( ref $value eq 'ARRAY' and $field ne '-cookie' and $field ne '-p3p' ) {
        croak "The $field header must be SCALAR. See 'perldoc CGI'";
    }

    $header->{ $field } = $value;

    return;
}

sub exists {
    my $header = shift->{header};
    my $field = _normalize_field_name( shift );
    exists $header->{ $field };
}

sub push {
    my ( $self, $field, $value ) = @_;

    if ( $self->exists( $field ) ) {
        my $old_value = $self->{header}->{ _normalize_field_name( $field ) };
        if ( ref $old_value eq 'ARRAY' ) {
            push @{ $old_value }, $value;
        }
        else {
            $self->set( $field => [ $old_value, $value ] );
        }
    }
    else {
        $self->set( $field => $value );
    }

    return;
}

{
    # suppose read-only
    my %ALIAS_OF = (
        '-content-type' => '-type',
        '-set-cookie'   => '-cookie',
    );
    
    # cache (how do we prove cache works?)
    my %norm_of = %ALIAS_OF;

    sub _normalize_field_name {
        my $field = shift;
        return unless $field;

        # return cached value if exists
        return $norm_of{ $field } if exists $norm_of{ $field };

        # lowercase $field
        my $norm = lc $field;

        # add initial dash if not exists
        $norm = "-$norm" unless $norm =~ /^-/;

        # use dashes instead of underscores
        $norm =~ tr{_}{-};

        # use alias if exists
        $norm = $ALIAS_OF{ $norm } if exists $ALIAS_OF{ $norm };

        $norm_of{ $field } = $norm;
    }
}

1;

__END__

=head1 NAME

Blosxom::Header - Missing interface to modify HTTP headers

=head1 SYNOPSIS

  package blosxom;
  our $header = { -type => 'text/html' };

  package plugin_foo;
  use Blosxom::Header;

  my $header = Blosxom::Header->new;
  my $value  = $header->get( 'Foo' );
  my $bool   = $header->exists( 'Foo' );

  $header->set( Foo => 'bar' );
  $header->delete( 'Foo' );

  my @cookies = $header->get( 'Set-Cookie' );
  $header->push( 'Set-Cookie' => 'foo' );

  my @p3p = $header->get( 'P3P' );
  $header->push( P3P => 'foo' );

  $header->{header}; # same reference as $blosxom::header

=head1 DESCRIPTION

Blosxom, a weblog application, exports a global variable $header
which is a reference to hash.
This application passes $header L<CGI>::header() to generate
HTTP headers.

When plugin developers modify HTTP headers, they must write as follows:

  package foo;
  $blosxom::header->{'-status'} = '304 Not Modified';

It's obviously bad practice.
The problem is multiple elements may specify the same field:

  package bar;
  $blosxom::header->{'status'} = '404 Not Found';

  package baz;
  $blosxom::header->{'-Status'} = '301 Moved Permanently';

Blosxom misses the interface to modify HTTP headers.

If you used this module, you might write as follows:

  package foo;
  use Blosxom::Header;
  my $header = Blosxom::Header->new;
  $header->set( Status => '304 Not Modified' );

You don't have to mind whether to put a dash before a key,
nor whether to make a key lowercased, any more.

=head2 METHODS

=over 4

=item $header = Blosxom::Header->new

Creates a new Blosxom::Header object.

=item $value = $header->get( 'Foo' )

Returns a value of the specified HTTP header.

=item $header->set( Foo => 'bar' )

Sets a value of the specified HTTP header.

=item $bool = $header->exists( 'Foo' )

Returns a Boolean value telling whether the specified HTTP header exists.

=item $header->delete( 'Foo' )

Deletes all the specified elements from HTTP headers.

=item $header->push( 'Set-Cookie' => 'foo' )

Pushes the Set-Cookie header onto HTTP headers.

=back

=head1 EXAMPLES

L<CGI>::header recognizes the following parameters.

=over 4

=item attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $header->set( attachment => 'foo.png' );

In this case, the outgoing header will be formatted as:

  Content-Disposition: attachment; filename="foo.png"

=item charset

Represents the character set sent to the browser.
If not provided, defaults to ISO-8859-1.

  $header->set( charset => 'utf-8' );

=item cookie

Represents the Set-Cookie headers.
The parameter can be an arrayref or a string.

  $header->set( cookie => [ 'foo', 'bar' ] );
  $header->set( cookie => 'baz' );

=item expires

Represents the Expires header.
You can specify an absolute or relative expiration interval.
The following forms are all valid for this field.

  $header->set( expires => '+30s' ); # 30 seconds from now
  $header->set( expires => '+10m' ); # ten minutes from now
  $header->set( expires => '+1h'  ); # one hour from now
  $header->set( expires => '-1d'  ); # yesterday
  $header->set( expires => 'now'  ); # immediately
  $header->set( expires => '+3M'  ); # in three months
  $header->set( expires => '+10y' ); # in ten years time

  # at the indicated time & date
  $header->set( expires => 'Thu, 25 Apr 1999 00:40:33 GMT' );

=item nph

If set to a true value,
will issue the correct headers to work with
a NPH (no-parse-header) script:

  $header->set( nph => 1 );

=item p3p

Will add a P3P tag to the outgoing header.
The parameter can be an arrayref or a space-delimited string.

  $header->set( p3p => [ qw/CAO DSP LAW CURa/ ] );
  $header->set( p3p => 'CAO DSP LAW CURa' );

In either case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"

=item type

Represents the Content-Type header.

  $header->set( type => 'text/plain' );

=back

=head1 DEPENDENCIES

L<Blosxom 2.0.0|http://blosxom.sourceforge.net/> or higher.

=head1 SEE ALSO

L<CGI>

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

