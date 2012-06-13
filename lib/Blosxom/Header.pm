package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use constant USELESS => 'Useless use of %s with no values';
use Blosxom::Header::Proxy;
use Carp qw/carp/;
use HTTP::Status qw/status_message/;

our $VERSION = '0.05002';


# Class methods

our $INSTANCE;

sub instance {
    my $class = shift;

    return $class if ref $class;
    return $INSTANCE if defined $INSTANCE;

    my %alias_of = (
        -content_type => '-type',
        -cookies      => '-cookie',
        -set_cookie   => '-cookie',
    );

    my $callback = sub {
        # lowercase a given string
        my $norm  = lc shift;

        # add an initial dash if not exist
        $norm = "-$norm" unless $norm =~ /^-/;

        # transliterate dashes into underscores in field names
        substr( $norm, 1 ) =~ tr{-}{_};

        $alias_of{ $norm } || $norm;
    };

    tie my %proxy => 'Blosxom::Header::Proxy', $callback;

    $INSTANCE = bless \%proxy => $class;
}


# Instance methods

sub is_initialized { scalar %{ $_[0] } }

sub get {
    my ( $self, $field ) = @_;
    my $value = $self->{ $field };
    return $value unless ref $value eq 'ARRAY';
    wantarray ? @{ $value } : $value->[0];
}

sub set {
    my ( $self, %fields ) = @_;
    return _carp( USELESS, 'set()' ) unless %fields;
    @{ $self }{ keys %fields } = values %fields;
    return;
}

sub delete {
    my ( $self, @fields ) = @_;
    return _carp( USELESS, 'delete()' ) unless @fields;
    delete @{ $self }{ @fields };
}

sub clear  { %{ $_[0] } = ()         }
sub exists { exists $_[0]->{ $_[1] } }

sub push_cookie { shift->_push( -cookie => @_ ) }
sub push_p3p    { shift->_push( -p3p    => @_ ) }

sub _push {
    my ( $self, $field, @values ) = @_;

    return _carp( USELESS, '_push()' ) unless @values;

    if ( my $value = $self->{ $field } ) {
        return push @{ $value }, @values if ref $value eq 'ARRAY';
        unshift @values, $value;
    }

    $self->{ $field } = @values > 1 ? \@values : $values[0];

    scalar @values;
}

{
    no strict 'refs';

    for my $method ( qw/attachment charset expires nph target type/ ) {
        my $field = "-$method";
        *$method = sub {
            my $self = shift;
            return $self->{ $field } = shift if @_;
            $self->{ $field };
        };
    }

    for my $method ( qw/cookie p3p/ ) {
        my $field = "-$method";
        *$method = sub {
            my $self = shift;
            return $self->{ $field } = [ @_ ] if @_ > 1;
            return $self->{ $field } = shift if @_;
            $self->{ $field };
        };
    }
}

sub status {
    my $self = shift;

    if ( @_ ) {
        my $code = shift;

        if ( my $message = status_message( $code ) ) {
            $self->{-status} = "$code $message";
            return $code;
        }

        carp( qq{Unknown status code "$code" passed to status()} );

        return;
    }

    if ( my $status = $self->{-status} ) {
        return substr( $status, 0, 3 );
    }

    return;
}


# Internal functions

sub _carp {
    my ( $format, @args ) = @_;
    carp( sprintf $format, @args );
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

Blosxom, an weblog application, globalizes C<$header> which is a reference to
a hash. This application passes C<$header> to C<CGI::header()> to generate HTTP
headers.

  package blosxom;
  use CGI;
  our $header = { -type => 'text/html' };
  # Loads plugins
  print CGI::header( $header );

C<header()> doesn't care whether keys of C<$header> are lowercased
nor starting with a dash, and also transliterates underscores into dashes
in field names.

=head2 HOW THIS MODULE NORMALIZES FIELD NAMES

To specify field names consistently, we need to normalize them.
If you follow one of normalization rules, you can modify C<$header>
consistently. This module normalizes field names as follows.

Remember how Blosxom initializes C<$header>:

  $header = { -type => 'text/html' };

A key C<-type> is starting with a dash and lowercased, and so this module
follows the same rules:

  'Status'  # not normalized
  'status'  # not normalized
  '-status' # normalized

How about C<Content-Length>? It contains a dash.
To avoid quoting when specifying hash keys, this module transliterates dashes
into underscores in field names:

  'Content-Length'  # not normalized
  '-content-length' # not normalized
  '-content_length' # normalized

If you follow the above normalization rule, you can modify C<$header> directly.
In other words, this module is compatible with the way modifying C<$header>
directly when you follow the above rule.

=head2 METHODS

=over 4

=item $header = Blosxom::Header->instance

Returns a current Blosxom::Header object instance or create a new one.

=item $bool = $header->is_initialized

Returns a Boolean value telling whether C<$blosxom::header> is initialized or
not. Blosxom initializes the variable just before C<blosxom::generate()> is
called. If C<$bool> was false, the following methods throw exceptions.

Internally, this method is a shortcut for

  $bool = ref $blosxom::header eq 'HASH';

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

Adds P3P tags to the P3P header.

=item $header->clear

This will remove all header fields.

=back

=head2 CONVENIENCE METHODS

The following methods were named after parameters recognized by
C<CGI::header()>.
They can both be used to read and to set the value of an attribute.
The value is set if you pass an argument to the method.
If the given attribute wasn't defined then C<undef> is returned.

=over 4

=item $header->attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $header->attachment( 'foo.png' );

In this case, the outgoing header will be formatted as:

  Content-Disposition: attachment; filename="foo.png"

=item $header->charset

Represents the character set sent to the browser.
If not provided, defaults to C<ISO-8859-1>.

  $header->charset( 'utf-8' );

NOTE: If C<< $header->type >> contains C<charset>, this attribute will be ignored.

=item $header->cookie

Represents the Set-Cookie headers.
The parameter can be an array.

  $header->cookie( 'foo', 'bar' );

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

Represents the P3P header.
The parameter can be an array or a space-delimited string.

  $header->p3p( qw/CAO DSP LAW CURa/ );
  $header->p3p( 'CAO DSP LAW CURa' );

In either case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"

=item $header->status

Represents HTTP status code.

  $header->status( 304 );

Don't pass a string which contains reason phrases:

  $header->status( '304 Not Modified' ); # Obsolete

=item $header->target

Represents the Window-Target header.

  $header->target( 'ResultsWindow' );

=item $header->type

The Content-Type header indicates the media type of the message content.
If not defined, defaults to C<text/html>.

  $header->type( 'text/plain' );

NOTE: If this attribute isn't defined, C<CGI::header()> will add the default
value. If you don't want to output the Content-Type header itself, you have to
set to an empty string:

  $header->type( q{} );

=back

=head1 DIAGNOSTICS

=over 4

=item $blosxom::header hasn't been initialized yet

You attempted to modify C<$blosxom::header>
before the variable was initialized.
See C<< $header->is_initialized >>.

=item Useless use of %s with no values

You used the C<push_cookie()> or C<push_p3p()> method with no argument
apart from the array,
like C<< $header->push_cookie() >> or C<< $header->push_p3p() >>.

=item Unknown status code "%d%d%d" passed to status()

The given status code is unknown to L<HTTP::Status>.

=back

=head1 DEPENDENCIES

L<Blosxom 2.0.0|http://blosxom.sourceforge.net/> or higher.

=head1 SEE ALSO

L<Blosxom::Header::Proxy>,
L<CGI>,
L<Class::Singleton>

=head1 ACKNOWLEDGEMENT

Blosxom was written by Rael Dornfest.
L<The Blosxom Development Team|http://sourceforge.net/projects/blosxom/>
succeeded the maintenance.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Ryo Anazawa (anazawa@cpan.org).
Patches are welcome.

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

