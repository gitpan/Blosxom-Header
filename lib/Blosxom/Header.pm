package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use parent qw/Exporter/;
use constant USELESS => 'Useless use of %s with no values';
use Blosxom::Header::Adapter;
use Carp qw/carp croak/;

our $VERSION = '0.05008';

our @EXPORT_OK = qw(
    header_get  header_set  header_exists header_delete
    header_push push_cookie push_p3p each_header
);

sub header_get    { __PACKAGE__->instance->get( @_ )    }
sub header_set    { __PACKAGE__->instance->set( @_ )    }
sub header_exists { __PACKAGE__->instance->exists( @_ ) }
sub header_delete { __PACKAGE__->instance->delete( @_ ) }
sub each_header   { __PACKAGE__->instance->each( @_ )   }

# The following function is obsolete and will be removed in 0.06
sub header_push { __PACKAGE__->instance->_push( @_ ) }

sub _carp {
    my ( $format, @args ) = @_;
    carp( sprintf $format, @args );
}

my $instance;

sub instance {
    my $class = shift;

    return $class if ref $class;
    return $instance if defined $instance;

    if ( $class->is_initialized ) {
        tie my %self => 'Blosxom::Header::Adapter' => $blosxom::header;
        return $instance = bless \%self, $class;
    }

    croak( q{$blosxom::header hasn't been initialized yet} );
}

sub has_instance { $instance }

sub is_initialized { ref $blosxom::header eq 'HASH' }

sub get {
    my ( $self, @fields ) = @_;
    return _carp( USELESS, 'get()' ) unless @fields;
    @{ $self }{ @fields };
}

sub set {
    my ( $self, %fields ) = @_;
    return _carp( USELESS, 'set()' ) unless %fields;
    @{ $self }{ keys %fields } = values %fields; # merge
    return;
}

sub delete {
    my ( $self, @fields ) = @_;
    return _carp( USELESS, 'delete()' ) unless @fields;
    delete @{ $self }{ @fields };
}

sub exists { exists $_[0]->{ $_[1] } }
sub clear  { %{ $_[0] } = ()         }

sub field_names { keys %{ $_[0] } }

sub each {
    my ( $self, $callback ) = @_;
    return each %{ $self } unless ref $callback eq 'CODE';
    my %header = %{ $self }; # copy
    while ( my @args = each %header ) { $callback->( @args ) }
}

sub is_empty { not %{ $_[0] } }
sub flatten  { ( %{ $_[0] } ) }

sub set_cookie {
    require CGI::Cookie;

    my $self  = shift;
    my $name  = shift;
    my $value = ref $_[0] eq 'HASH' ? shift : { value => shift };

    my @old_cookies;
    if ( my $cookies = $self->{Set_Cookie} ) {
        @old_cookies = ref $cookies eq 'ARRAY' ? @{ $cookies } : $cookies;
    }

    my @new_cookies;
    for my $cookie ( @old_cookies ) {
        next if ref $cookie eq 'CGI::Cookie' and $cookie->name eq $name;
        push @new_cookies, $cookie;
    }

    push @new_cookies, CGI::Cookie->new({ name => $name, %$value });

    $self->{Set_Cookie} = @new_cookies > 1 ? \@new_cookies : $new_cookies[0];

    return;
}

sub get_cookie {
    my ( $self, $name ) = @_;

    my @cookies;
    if ( my $cookies = $self->{Set_Cookie} ) {
        @cookies = ref $cookies eq 'ARRAY' ? @{ $cookies } : $cookies;
    }

    my @values;
    for my $cookie ( @cookies ) {
        next unless ref $cookie eq 'CGI::Cookie';
        next unless $cookie->name eq $name;
        push @values, $cookie;
    }

    wantarray ? @values : $values[0];
}

# This method/function is obsolete and will be removed in 0.06
sub push_cookie {
    require CGI::Cookie;

    my $self = ref $_[0] ? shift : __PACKAGE__->instance;

    my @cookies;
    for my $cookie ( @_ ) {
        $cookie = CGI::Cookie->new( $cookie ) if ref $cookie eq 'HASH';
        push @cookies, $cookie; 
    }

    $self->_push( Set_Cookie => @cookies );
}

sub push_p3p {
    my $self = ref $_[0] ? shift : __PACKAGE__->instance;
    $self->_push( P3P => @_ );
}

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

sub attachment { shift->_adapter->attachment( @_ ) }
sub nph        { shift->_adapter->nph( @_ )        }

sub _adapter { tied %{ $_[0] } }

sub charset {
    my $self = shift;
    my $type = $self->{Content_Type};
    my ( $charset ) = $type =~ /charset=([^;]+)/ if $type;
    return unless $charset;
    uc $charset;
}

# This method is obsolete and will be removed in 0.06
sub cookie {
    my $self = shift;

    if ( @_ ) {
        delete $self->{Set_Cookie};
        $self->push_cookie( @_ );
    }
    elsif ( my $cookie = $self->{Set_Cookie} ) {
        my @cookies = ref $cookie eq 'ARRAY' ? @{ $cookie } : ( $cookie );
        return wantarray ? @cookies : $cookies[0];
    }

    return;
}

sub last_modified { shift->_date_header( Last_modified => $_[0] ) }
sub date          { shift->_date_header( Date => $_[0] )          }

sub _date_header {
    require HTTP::Date;

    my ( $self, $field, $mtime ) = @_;

    if ( defined $mtime ) {
        $self->{ $field } = HTTP::Date::time2str( $mtime );
        return;
    }
    elsif ( my $date = $self->{ $field } ) {
        return HTTP::Date::str2time( $date );
    }

    return;
}

sub expires {
    require HTTP::Date;
    my $self = shift;
    return $self->{Expires} = shift if @_;
    my $expires = $self->{Expires};
    return unless $expires;
    HTTP::Date::str2time( $expires );
}

sub p3p {
    my $self = shift;

    if ( @_ ) {
        my @tags = @_ > 1 ? @_ : split / /, shift;
        $self->{P3P} = @tags > 1 ? \@tags : $tags[0];
    }
    elsif ( my $tags = $self->{P3P} ) {
        my @tags = ref $tags eq 'ARRAY' ? @{ $tags } : ( $tags );
        @tags = map { split / / } @tags;
        return wantarray ? @tags : $tags[0];
    }

    return;
}

sub type {
    my $self = shift;
    return $self->{Content_Type} = shift if @_;
    my $content_type = $self->{Content_Type};
    return q{} unless $content_type;
    my ( $type, $rest ) = split /;\s*/, $content_type, 2;
    wantarray ? ( lc $type, $rest ) : lc $type;
}

sub status {
    my $self = shift;

    if ( @_ ) {
        require HTTP::Status;
        my $code = shift;
        my $message = HTTP::Status::status_message( $code );
        return $self->{Status} = "$code $message" if $message;
        carp( qq{Unknown status code "$code" passed to status()} );
    }
    elsif ( my $status = $self->{Status} ) {
        return substr( $status, 0, 3 );
    }

    return;
}

sub target {
    my $self = shift;
    return $self->{Window_Target} = shift if @_;
    $self->{Window_Target};
}

1;

__END__

=head1 NAME

Blosxom::Header - Object representing CGI response headers

=head1 SYNOPSIS

  # Object-oriented interface

  use Blosxom::Header;

  my $header = Blosxom::Header->instance;

  $header->set(
      Status        => '304 Not Modified',
      Last_Modified => 'Wed, 23 Sep 2009 13:36:33 GMT',
  );

  my $status = $header->get( 'Status' );
  my @deleted = $header->delete( qw/Content-Disposition Content-Length/ );


  # Procedural interface

  use Blosxom::Header qw/header_set header_get header_delete/;

  header_set(
      Status        => '304 Not Modified',
      Last_Modified => 'Wed, 23 Sep 2009 13:36:33 GMT',
  );

  my $status = header_get( 'Status' );
  my @deleted = header_delete( qw/Content-Disposition Content-Length/ );

=head1 DESCRIPTION

This module provides Blosxom plugin developers
with an interface to handle L<CGI> response headers.

=head2 VARIABLE

=over 4

=item $Header

This variable isn't exported any more. Sorry for incovenience :(

=back

=head2 FUNCTIONS

The following functions are exported on demand.

=over 4

=item @values = header_get( @fields )

A synonym for C<< Blosxom::Header->instance->get() >>.

=item header_set( $field => $value )

=item header_set( $f1 => $v2, $f2 => $v2, ... )

A synonym for C<< Blosxom::Header->instance->set() >>.

=item $bool = header_exists( $field )

A synonym for C<< Blosxom::Header->instance->exists() >>.

=item @deleted = header_delete( @fields )

A synonym for C<< Blosxom::Header->instance->delete() >>.

=item push_cookie( @cookies )

This function is obsolete and will be removed in 0.06.
See L<"HANDLING COOKIES">.

=item push_p3p( @tags )

A synonym for C<< Blosxom::Header->instance->push_p3p() >>.

=item each_header( CodeRef )

=item $field = each_header()

=item ( $field, $value ) = each_header()

A synonym for C<< Blosxom::Header->instance->each() >>.

=item header_push()

This function is obsolete and will be removed in 0.06.

=back

=head2 CLASS METHODS

=over 4

=item $header = Blosxom::Header->instance

Returns a current Blosxom::Header object instance or create a new one.

=item $header = Blosxom::Header->has_instance

Returns a reference to any existing instance or C<undef> if none is defined.

=item $bool = Blosxom::Header->is_initialized

Returns a Boolean value telling whether C<$blosxom::header> is initialized or
not. Blosxom initializes the variable just before C<blosxom::generate()> is
called. If C<$bool> was false, C<instance()> would throw an exception.

Internally, this method is a shortcut for

  $bool = ref $blosxom::header eq 'HASH';

=back

=head2 INSTANCE METHODS

=over 4

=item $value = $header->get( $field )

=item @values = $header->get( @fields )

Returns the value of one or more header fields.
Accepts a list of field names case-insensitive.
You can use underscores as a replacement for dashes in header names.

=item $header->set( $field => $value )

=item $header->set( $f1 => $v1, $f2 => $v2, ... )

Sets the value of one or more header fields.
Accepts a list of named arguments.

The $value argument must be a plain string, except for when the Set-Cookie
or P3P header is specified.
In exceptional cases, $value may be a reference to an array.

  $header->set(
      Set_Cookie => [ $cookie1, $cookie2 ],
      P3P        => [ 'CAO', 'DSP', 'LAW', 'CURa' ],
  );

=item $bool = $header->exists( $field )

Returns a Boolean value telling whether the specified HTTP header exists.

=item @deleted = $header->delete( @fields )

Deletes the specified fields from HTTP headers.
Returns values of deleted fields.

=item $header->push_cookie( @cookies )

This method is obsolete and will be removed in 0.06.
Use C<< $header->set_cookie >> instead.

=item $header->push_p3p( @tags )

Adds P3P tags to the P3P header.
Accepts a list of P3P tags.

  # get P3P tags
  my @tags = $header->p3p; # ( 'CAO', 'DSP', 'LAW' )

  # add P3P tags
  $header->push_p3p( 'CURa' );

  @tags = $header->p3p; # ( 'CAO', 'DSP', 'LAW', 'CURa' )

=item $header->clear

This will remove all header fields.

Internally, this method is a shortcut for

  %{ $blosxom::header } = ( -type => q{} );

=item @fields = $header->field_names

Returns the list of distinct names for the fields present in the header.
The field names have case as returned by C<CGI::header()>.
In scalar context return the number of distinct field names.

=item $header->each( \&callback )

Apply a subroutine to each header field in turn.
The callback routine is called with two parameters;
the name of the field and a value.
Any return values of the callback routine are ignored.

  $header->each(sub {
      my ( $field, $value ) = @_;
      ...
  });

=item $field = $header->each

=item ( $field, $value ) = $header->each

When called in list context, returns two parameters;
the name of the field and a value, so that you can iterate over it.
When called in scalar context, returns only the field name
for the next header field.
When the header is entirely read, a null array is returned in list context,
and C<undef> in scalar context.

  while ( my ( $field, $value ) = $header->each ) {
      print "$field: $value\n";
  }

You can reset the iterator by calling C<< $header->field_names >>.

If you C<set()> or C<delete()> header fields while you're iterating
over it, you may get entries skipped or duplicated, so don't.

=item $bool = $header->is_empty

Returns a Boolean value telling whether C<< $header->field_names >>
returns a null array or not.

  $header->clear;
  my $is_empty = $header->is_empty; # true

=item @headers = $header->flatten

Returns a new array that is a one-dimensional flattening of header fields.

  my @headers = $header->flatten;
  # => ( 'P3P', [ 'CAO', 'DSP' ], 'Content-Type', 'text/plain' )

NOTE: This method does not flatten recursively.

=back

=head2 HANDLING COOKIES

C<cookie()> and C<push_cookie()> are obsolete and will be removed in 0.06.
These methods was replaced with C<set_cookie()> and C<get_cookie()>.

=over 4

=item $header->set_cookie( $name => $value )

=item $header->set_cookie( $name => { value => $value, ... } )

Overwrites existent cookie.

  $header->set_cookie( ID => 123456 );

  $header->set_cookie(
     ID => {
         value   => '123456',
         path    => '/',
         domain  => '.example.com',
         expires => '+3M',
      }
  );

=item $cookie = $header->get_cookie( $name )

Returns a L<CGI::Cookie> object whose C<name()> is stringwise equal to C<$name>.

  my $id = $header->get_cookie( 'ID' ); # CGI::Cookie object
  my $value = $id->value; # 123456

=back

=head2 CONVENIENCE METHODS

Most of these methods were named after parameters recognized by
C<CGI::header()>.
These can both be used to read and to set the value of a header.
The value is set if you pass an argument to the method.
If the given header wasn't defined then C<undef> would be returned.

Methods that deal with dates/times  always convert their value to
system time (seconds since Jan 1, 1970).

=over 4

=item $header->attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $header->attachment( 'genome.jpg' );
  my $attachment = $header->attachment; # genome.jpg

  my $disposition = $header->get( 'Content-Disposition' );
  # => 'attachment; filename="genome.jpg"'

=item $header->charset

Returns the upper-cased character set specified in the Content-Type header.

  $charset = $header->charset; # UTF-8 (Readonly)

=item $header->cookie

This method is obsolete and will be removed in 0.06.
Use C<< $header->get_cookie >> or C<< $header->set_cookie >> instead.

=item $header->date

This header represents the date and time at which the message
was originated. This method expects machine time when the header
value is set.

  $header->date( time ); # set current date

NOTE: If any of expires(), nph() or cookie() was set,
the Date header would be added automatically
and you couldn't modify the value.
In other words, the Date header would be fixed.

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

  # another representation of 'now'
  $header->expires( time );

=item $header->last_modified

This header indicates the date and time at which the resource was
last modified. This method expects machine time when the header value is set.

  # check if document is more than 1 hour old
  if ( my $last_modified = $header->last_modified ) {
      if ( $last_modified < time - 60 * 60 ) {
          ...
      }
  }

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

  my @tags = $header->p3p; # ( 'CAO', 'DSP', 'LAW', 'CURa' )

In this case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"

=item $header->status

Represents HTTP status code.

  $header->status( 304 );
  my $code = $header->status; # 304

cf.

  $header->set( Status => '304 Not Modified' );
  my $status = $header->get( 'Status' ); # 304 Not Modified

=item $header->target

Represents the Window-Target header.

  $header->target( 'ResultsWindow' );
  my $target = $header->target; # ResultsWindow

cf.

  $header->set( Window_Target => 'ResultsWindow' );
  $target = $header->get( 'Window-Target' ); # ResultsWindow

=item $header->type

The Content-Type header indicates the media type of the message content.

  $header->type( 'text/plain; charset=utf-8' );

The above is a shortcut for

  $header->set( Content_Type => 'text/plain; charset=utf-8' );

The value returned will be converted to lower case, and potential parameters
will be chopped off and returned as a separate value if in an array context.

  my $type = $header->type; # 'text/html'
  my @type = $header->type; # ( 'text/html', 'charset=ISO-8859-1' )

cf.

  my $content_type = $header->get( 'Content-Type' );
  # => 'text/html; charset=ISO-8859-1'

If there is no such header field, then the empty string is returned.
This makes it safe to do the following:

  if ( $header->type eq 'text/html' ) {
      ...
  }

=back

=head1 DIAGNOSTICS

=over 4

=item $blosxom::header hasn't been initialized yet

You attempted to create a Blosxom::Header object
before the variable was initialized.
See C<< Blosxom::Header->is_initialized() >>.

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

L<Blosxom::Header::Adapter>,
L<HTTP::Headers>,
L<Plack::Util>,
L<Class::Singleton>

=over 4

=item D. Robinson and K.Coar, "The Common Gateway Interface (CGI) Version 1.1",
L<RFC 3875|http://tools.ietf.org/html/rfc3875#section-6>, October 2004

=back

=head1 ACKNOWLEDGEMENT

Blosxom was originally written by Rael Dornfest.
L<The Blosxom Development Team|http://sourceforge.net/projects/blosxom/>
succeeded to the maintenance.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to ANAZAWA (anazawa@cpan.org).
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

