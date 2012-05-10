package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use Carp qw/carp croak/;

our $VERSION = '0.04001';

# Parameters recognized by CGI::header()
use constant ATTRIBUTES
    => qw/attachment charset cookie expires nph p3p status target type/;

# Naming conventions
#   $field : raw field name (e.g. Foo-Bar)
#   $norm  : normalized field name (e.g. -foo_bar)

our $INSTANCE;

sub instance {
    my $class = shift;
    return $INSTANCE if defined $INSTANCE;
    tie my %header, "$class";
    $INSTANCE = bless \%header, $class;
}

sub get {
    my ( $self, $field ) = @_;
    my $value = $self->{ $field };
    return $value unless ref $value eq 'ARRAY';
    return @{ $value } if wantarray;
    return $value->[0] if defined wantarray;
    carp( 'Useless use of get() in void context' );
}

sub set {
    my ( $self, @fields ) = @_;

    return unless @fields;

    if ( @fields == 2 ) {
        $self->{ $fields[0] } = $fields[1];
    }
    elsif ( @fields % 2 == 0 ) {
        while ( my ( $field, $value ) = splice @fields, 0, 2 ) {
            $self->{ $field } = $value;
        }
    }
    else {
        croak( 'Odd number of elements are passed to set()' );
    }

    return;
}

sub delete {
    my $self = shift;
    delete @{ $self }{ @_ };
}

sub clear  { %{ $_[0] } = ()         }
sub exists { exists $_[0]->{ $_[1] } }

sub push_cookie { shift->_push( -cookie => @_ ) }
sub push_p3p    { shift->_push( -p3p    => @_ ) }

sub _push {
    my ( $self, $field, @values ) = @_;

    unless ( @values ) {
        carp( 'Useless use of _push() with no values' );
        return;
    }

    if ( my $value = $self->{ $field } ) {
        return push @{ $value }, @values if ref $value eq 'ARRAY';
        unshift @values, $value;
    }

    $self->{ $field } = @values > 1 ? \@values : $values[0];

    return scalar @values if defined wantarray;
    return;
}

# Make accessors
for my $attr ( ATTRIBUTES ) {
    my $slot  = __PACKAGE__ . "::$attr";
    no strict 'refs';
    *$slot = sub {
        my $self = shift;
        $self->{ $attr } = shift if @_;
        $self->get( $attr );
    };
}

# tie() interface

sub TIEHASH {
    my $class = shift;

    unless ( ref $blosxom::header eq 'HASH' ) {
        croak( "\$blosxom::header hasn't been initialized yet" );
    }

    bless { header => $blosxom::header }, $class;
}

sub FETCH {
    my ( $self, $field ) = @_;
    my $norm = _normalize_field_name( $field );
    $self->{header}->{$norm};
}

sub STORE {
    my ( $self, $field, $value ) = @_;
    my $norm = _normalize_field_name( $field );
    $self->{header}->{$norm} = $value;
    return;
}

sub DELETE {
    my ( $self, $field ) = @_;
    my $norm = _normalize_field_name( $field );
    delete $self->{header}->{$norm};
}

sub CLEAR {
    my $self = shift;
    %{ $self->{header} } = ();
}

sub EXISTS {
    my ( $self, $field ) = @_;
    my $norm = _normalize_field_name( $field );
    exists $self->{header}->{$norm};
}

sub FIRSTKEY {
    my $self = shift;
    keys %{ $self->{header} };
    each %{ $self->{header} };
}

sub NEXTKEY {
    my $self = shift;
    each %{ $self->{header} };
}

{
    my %ALIAS_OF = (
        -content_type => '-type',
        -set_cookie   => '-cookie',
        -cookies      => '-cookie',
    );

    sub _normalize_field_name {
        my $norm = lc shift;

        # add an initial dash if not exists
        $norm = "-$norm" unless $norm =~ /^-/;

        # use underscores instead of dashes 
        substr( $norm, 1 ) =~ tr{-}{_};

        $ALIAS_OF{ $norm } || $norm;
    }
}

1;

__END__

=head1 NAME

Blosxom::Header - Missing interface to modify HTTP headers

=head1 SYNOPSIS

  use Blosxom::Header;

  my $header = Blosxom::Header->instance;

  $header->set(
      Status        => '304 Not Modified',
      Last_Modified => 'Wed, 23 Sep 2009 13:36:33 GMT',
  );

  my $status  = $header->get( 'Status' );
  my $bool    = $header->exists( 'ETag' );
  my @deleted = $header->delete( qw/Content-Disposition Content-Length/ );

  $header->push_cookie( @cookies );
  $header->push_p3p( @p3p );

  $header->clear;

=head1 DESCRIPTION

Blosxom, an weblog application, globalizes $header which is a reference to
hash. This application passes $header L<CGI>::header() to generate HTTP
headers.

  package blosxom;
  use CGI;
  our $header = { -type => 'text/html' };
  # Loads plugins
  print CGI::header( $header );

header() doesn't care whether keys of $header are lowecased
nor starting with a dash.
The problem is multiple elements of $header may specify the same field:

  package plugin_foo;
  $blosxom::header->{-status} = '304 Not Modified';

  package plugin_bar;
  $blosxom::header->{Status} = '404 Not Found';

In above way, plugin developers can't modify HTTP headers consistently.
Blosxom misses the interface.
This module provides you the alternative way, and also some convenient methods
described below.

=head2 METHODS

=over 4

=item $header = Blosxom::Header->instance

Returns a current Blosxom::Header object instance or create a new one.

=item $header->set( $field => $value )

=item $header->set( $f1 => $v1, $f2 => $v2, ... )

Sets the value of one or more header fields.
Accepts a list of named arguments.
The header field name ($field) isn't case-sensitive.
You can use '_' as a replacement for '-' in header names.

The $value argument must be a plain string, except for when the Set-Cookie
or P3P header is specified.
In exceptional cases, $value may be a reference to an array.

  $header->set( Set_Cookie => [ $cookie1, $cookie2 ] );
  $header->set( P3P => [ qw/CAO DSP LAW CURa/ ] );

=item $value = $header->get( $field )

=item @values = $header->get( $field )

Returns a value of the specified HTTP header.
In list context, a list of scalars is returned.

  my @cookie = $header->get( 'Set-Cookie' );
  my @p3p    = $header->get( 'P3P' );

=item $bool = $header->exists( $field )

Returns a Boolean value telling whether the specified HTTP header exists.

=item @deleted = $header->delete( @fields )

Deletes the specified elements from HTTP headers.
Returns values of deleted elements.

=item $header->push_cookie( @cookies )

Pushes the Set-Cookie headers onto HTTP headers.
Returns the number of the elements following the completed
push_cookie().  

=item $header->push_p3p( @p3p )

  $header->push_p3p( qw/foo bar/ );

=item $header->clear

This will remove all header fields.

=back

=head2 ATTRIBUTES

These methods can both be used to get() and set() the value of an attribute.
The attribute value is set if you pass an argument to the method.
If the given attribute didn't exists then undef is returned.

=over 4

=item $header->attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $header->attachment( 'foo.png' );

In this case, the outgoing header will be formatted as:

  Content-Disposition: attachment; filename="foo.png"

=item $header->charset

Represents the character set sent to the browser.
If not provided, defaults to ISO-8859-1.

  $header->charset( 'utf-8' );

NOTE: If $header->type() contains 'charset', this attribute will be ignored.

=item $header->cookie

Represents the Set-Cookie headers.
The parameter can be an arrayref or a string.

  $header->cookie( [ 'foo', 'bar' ] );
  $header->cookie( 'baz' );

=item $header->expires

The Expires header gives the date and time after which the entity should be
considered stale.
You can specify an absolute or relative expiration interval.
The following forms are all valid for this field:

  $header->expires( '+30s' ); # 30 seconds from now
  $header->expires( '+10m' ); # ten minutes from now
  $header->expires( '+1h'  ); # one hour from now
  $header->expires( '-1d'  ); # yesterday
  $header->expires( 'now'  ); # immediately
  $header->expires( '+3M'  ); # in three months
  $header->expires( '+10y' ); # in ten years time

  # at the indicated time & date
  $header->expires( 'Thu, 25 Apr 1999 00:40:33 GMT' );

=item $header->nph

If set to a true value,
will issue the correct headers to work with
a NPH (no-parse-header) script:

  $header->nph( 1 );

=item $header->p3p

Will add a P3P tag to the outgoing header.
The parameter can be an arrayref or a space-delimited string.

  $header->p3p( [ qw/CAO DSP LAW CURa/ ] );
  $header->p3p( 'CAO DSP LAW CURa' );

In either case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"

=item $header->status

Represents the Status header.

  $header->status( '304 Not Modified' );

=item $header->target

Represents the Window-Target header.

  $header->target( 'ResultsWindow' );

=item $header->type

The Content-Type header indicates the media type of the message content.
If not defined, defaults to 'text/html'.

  $header->type( 'text/plain' );

NOTE: If you don't want to output the Content-Type header, 
you have to set to an empty string:

  $header->type( q{} );

=back

=head1 DEPENDENCIES

L<Blosxom 2.0.0|http://blosxom.sourceforge.net/> or higher.

=head1 SEE ALSO

L<CGI>,
L<Class::Singleton>,
L<perltie>

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

