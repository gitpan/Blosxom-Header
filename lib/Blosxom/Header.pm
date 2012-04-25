package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use Carp qw/carp croak/;

# parameters recognized by CGI::header()
use constant ATTRIBUTES
    => qw/attachment charset cookie expires nph p3p status target type/;

our $VERSION = '0.03004';

sub new {
    my $class = shift;
    my $header = shift || $blosxom::header;
    croak( 'Not a HASH reference' ) unless ref $header eq 'HASH';
    bless { header => $header }, $class;
}

sub get {
    my $self = shift;
    my $field = _normalize_field_name( shift );
    my $value = $self->{header}->{$field};
    return $value unless ref $value eq 'ARRAY';
    return @{ $value } if wantarray;
    return $value if defined wantarray;
}

sub delete {
    my $self = shift;
    my @fields = map { _normalize_field_name( $_ ) } @_;
    delete @{ $self->{header} }{ @fields };
}

sub exists {
    my $self = shift;
    my $field = _normalize_field_name( shift );
    exists $self->{header}->{$field};
}

sub clear {
    my $self = shift;
    %{ $self->{header} } = ();
}

sub set {
    my ( $self, @fields ) = @_;

    if ( @fields == 2 ) {
        $self->_set( @fields );
    }
    elsif ( @fields % 2 == 0 ) {
        while ( my ( $field, $value ) = splice @fields, 0, 2 ) {
            $self->_set( $field => $value );
        }
    }
    else {
        croak( 'Odd number of elements are passed to set()' );
    }

    return;
}

sub _set {
    my $self  = shift;
    my $field = _normalize_field_name( shift );
    my $value = shift;

    $self->{header}->{$field} = $value;

    return;
}

sub push_cookie { shift->_push( -cookie => @_ ) }
sub push_p3p    { shift->_push( -p3p    => @_ ) }

sub _push {
    my $self   = shift;
    my $field  = _normalize_field_name( shift );
    my @values = @_;

    unless ( @values ) {
        carp( 'Useless use of _push() with no values' );
        return;
    }

    if ( my $old_value = $self->{header}->{$field} ) {
        return push @{ $old_value }, @values if ref $old_value eq 'ARRAY';
        unshift @values, $old_value;
    }

    $self->_set( $field => @values > 1 ? \@values : $values[0] );

    # returns the number of elements in @values like CORE::push
    scalar @values if defined wantarray;
}

# Will be removed in 0.04
sub push { shift->_push( @_ ) }

# make accessors
for my $method ( ATTRIBUTES ) {
    my $slot  = __PACKAGE__ . "::$method";
    my $field = "-$method";

    no strict 'refs';

    *$slot = sub {
        my $self = shift;
        $self->_set( $field => shift ) if @_;
        $self->get( $field );
    };
}

# tie() interface 

sub TIEHASH { shift->new( @_ )    }
sub FETCH   { shift->get( @_ )    }
sub STORE   { shift->_set( @_ )   }
sub EXISTS  { shift->exists( @_ ) }
sub DELETE  { shift->delete( @_ ) }
sub CLEAR   { shift->clear        }

sub FIRSTKEY {
    my $self = shift;
    keys %{ $self->{header} };
    my $first_key = each %{ $self->{header} };
    _denormalize_field_name( $first_key ) if $first_key;
}

sub NEXTKEY {
    my $self = shift;
    my $next_key = each %{ $self->{header} };
    _denormalize_field_name( $next_key ) if $next_key;
}

# Utilities

{
    my %ALIAS_OF = (
        '-content-type' => '-type',
        '-set-cookie'   => '-cookie',
        '-cookies'      => '-cookie',
    );

    sub _normalize_field_name {
        my $norm = lc shift;

        # add initial dash if not exists
        $norm = "-$norm" unless $norm =~ /^-/;

        # use dashes instead of underscores
        $norm =~ tr{_}{-};

        # return alias if exists
        $ALIAS_OF{ $norm } || $norm;
    }
}

{
    my %IS_ATTRIBUTE = map { $_ => 1 } ATTRIBUTES;

    sub _denormalize_field_name {
        my $field = shift;
        $field =~ s/^-//;
        return $field if $IS_ATTRIBUTE{ $field }; 
        ucfirst $field; 
    }
}

1;

__END__

=head1 NAME

Blosxom::Header - Missing interface to modify HTTP headers

=head1 SYNOPSIS

  use Blosxom::Header;

  my $header = Blosxom::Header->new;

  $header->set(
      Status        => '304 Not Modified',
      Last_Modified => 'Wed, 23 Sep 2009 13:36:33 GMT',
  );

  my $status  = $header->get( 'Status' );
  my $bool    = $header->exists( 'ETag' );
  my @deleted = $header->delete( qw/Content_Disposition Content_Length/ );

  $header->push_cookie( @cookies );
  $header->push_p3p( @p3p );

  $header->clear;

  # tie() interface (EXPERIMENTAL)

  tie my %header, 'Blosxom::Header';

  $header{Status} = '304 Not Modified';

  my $value   = $header{Status}; 
  my $bool    = exists $header{Status}; 
  my $deleted = delete $header{Status};
  my @keys    = keys %header;

  %header = ();

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

=item $header = Blosxom::Header->new

Creates a new Blosxom::Header object.

=item $header->set( $field => $value )

=item $header->set( $f1 => $v1, $f2 => $v2, ... )

Sets the value of one or more header fields.
Accepts a list of named arguments.
The header field name ($field) isn't case-sensitive.
We follow L<HTTP::Headers>' way:

  "To make the life easier for perl users who wants to avoid quoting before the
  => operator, you can use '_' as a replacement for '-' in header names."

The $value argument must be a plain string, except for when the Set-Cookie
or P3P header is specified.
In exceptional cases, $value may be a reference to an array.

  $header->set( Set_Cookie => [ $cookie1, $cookie2 ] );
  $header->set( P3P => [ qw/CAO DSP LAW CURa/ ] );

=item $value = $header->get( $field )

=item @values = $header->get( $field )

Returns a value of the specified HTTP header.
In list context, a list of scalars is returned.

  my @cookie = $header->get( 'Set_Cookie' );
  my @p3p    = $header->get( 'P3P' );

=item $bool = $header->exists( $field )

Returns a Boolean value telling whether the specified HTTP header exists.

=item @deleted = $header->delete( @fields )

Deletes the specified elements from HTTP headers.
Returns values of deleted elements.

=item $header->push( $field => @values )

This method is deprecated and will be removed in 0.04.
Use push_cookie() or push_p3p() instead.
An example convension is:

  $header->push( Set_Cookie => @cookies );
  $header->push( P3P => @p3p );

  # Becomes

  $header->push_cookie( @cookies );
  $header->push_p3p( @p3p );

=item $header->push_cookie( @cookies )

Pushes the Set-Cookie headers onto HTTP headers.
Returns the number of the elements following the completed
push_cookie().  

  use CGI::Cookie;

  my $cookie = CGI::Cookie->new(
      -name  => 'ID',
      -value => 123456,
  );

  $header->push_cookie( $cookie );

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

