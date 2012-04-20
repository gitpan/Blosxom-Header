package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use Carp qw/carp croak/;

our $VERSION = '0.03002';

sub new {
    my $class = shift;
    my $header = shift || $blosxom::header;
    croak( 'Not a HASH reference' ) unless ref $header eq 'HASH';
    bless { header => $header }, $class;
}

sub get {
    my $header = shift->{header};
    my $field = _normalize_field_name( shift );
    my $value = $header->{ $field };
    return $value unless ref $value eq 'ARRAY';
    wantarray ? @{ $value } : $value->[0];
}

sub delete {
    my $header = shift->{header};
    my @fields = map { _normalize_field_name( $_ ) } @_;
    delete @{ $header }{ @fields };
}

sub exists {
    my $header = shift->{header};
    my $field = _normalize_field_name( shift );
    exists $header->{ $field };
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

{
    my %isa_ArrayRef = (
        -cookie => 1,
        -p3p    => 1,
    );

    sub _set {
        my $header = shift->{header};
        my $field  = _normalize_field_name( shift );
        my $value  = shift;

        croak( "The $field header can't be an ARRAY reference" )
            if ref $value eq 'ARRAY' and !$isa_ArrayRef{ $field };

        $header->{ $field } = $value;

        return;
    }
}

sub _push {
    my ( $self, $field, @values ) = @_;

    unless ( @values ) {
        carp( 'Useless use of _push() with no values' );
        return;
    }

    my $norm = _normalize_field_name( $field );

    if ( my $old_value = $self->{header}->{$norm} ) {
        return CORE::push @{ $old_value }, @values if ref $old_value eq 'ARRAY';
        unshift @values, $old_value;
    }

    $self->_set( $field => @values > 1 ? \@values : $values[0] );

    scalar @values;
}

# Will be removed in 0.04
sub push { shift->_push( @_ ) }

sub push_cookie { shift->_push( Set_Cookie => @_ ) }
sub push_p3p    { shift->_push( P3P        => @_ ) }

{
    # cache
    my %norm_of = (
        Content_Type => '-type',
        Expires      => '-expires',
        P3P          => '-p3p',
        Set_Cookie   => '-cookie',
        attachment   => '-attachment',
        charset      => '-charset',
        nph          => '-nph',
        target       => '-target',
    );

    # make accessors
    while ( my ( $field, $norm ) = each %norm_of ) {
        $norm =~ s/^-//;

        no strict 'refs';

        *{$norm} = sub {
            my $self = shift;
            $self->_set( $field => shift ) if @_;
            $self->get( $field );
        };
    }

    sub _normalize_field_name {
        my $field = shift;

        return unless $field;

        # return cache if exists
        return $norm_of{ $field } if exists $norm_of{ $field };

        # lowercase $field
        my $norm = lc $field;

        # add initial dash if not exists
        $norm = "-$norm" unless $norm =~ /^-/;

        # use dashes instead of underscores
        $norm =~ tr{_}{-};

        # use alias if exists
        $norm = '-type'   if $norm eq '-content-type';
        $norm = '-cookie' if $norm eq '-set-cookie';

        $norm_of{ $field } = $norm;
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

  my $status = $header->get( 'Status' );
  my $bool   = $header->exists( 'ETag' );

  my @deleted = $header->delete( qw/Content_Disposition Content_Length/ );

  $header->push_cookie( @cookies );
  $header->push_p3p( @p3p );

  $header->{header}; # same reference as $blosxom::header

=head1 DESCRIPTION

Blosxom, an weblog application, exports a global variable $header
which is a reference to hash. This application passes $header L<CGI>::header()
to generate HTTP response headers.

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
or P3P response header is specified.
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

=back

=head2 ACCESSORS

These methods can both be used to get() and set() the value of a header.
The header value is set if you pass an argument to the method.
If the given header didn't exists then undef is returned.

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

=item $header->target

Represents the Window-Target header.

  $header->target( 'ResultsWindow' );

=item $header->type

The Content-Type header indicates the media type of the message content.

  $header->type( 'text/plain' );

=back

=head1 DEPENDENCIES

Perl 5.8.9 or higher.

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

