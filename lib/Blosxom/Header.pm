package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use parent qw/Exporter/;
use overload '%{}' => 'as_hashref', 'bool' => 'boolify', 'fallback' => 1;
use Blosxom::Header::Adapter;
use Carp qw/carp croak/;
use HTTP::Date ();

our $VERSION = '0.05009';

our @EXPORT_OK = qw(
    header_get  header_set  header_exists header_delete header_iter
    header_push push_cookie push_p3p each_header
);

sub header_get    { __PACKAGE__->instance->get( @_ )    }
sub header_set    { __PACKAGE__->instance->set( @_ )    }
sub header_exists { __PACKAGE__->instance->exists( @_ ) }
sub header_delete { __PACKAGE__->instance->delete( @_ ) }
sub header_iter   { __PACKAGE__->instance->each( @_ )   }

# The following functions are obsolete and will be removed in 0.06
sub header_push { __PACKAGE__->instance->_push( @_ ) }
*each_header = \&header_iter;

my %str2time;
sub _str2time { $str2time{ $_[0] } ||= HTTP::Date::str2time( $_[0] ) }

my %time2str;
sub _time2str { $time2str{ $_[0] } ||= HTTP::Date::time2str( $_[0] ) }

my $instance;

my %header;
my $adapter;

sub instance {
    my $class = shift;

    return $class if ref $class;
    return $instance if defined $instance;

    if ( $class->is_initialized ) {
        $adapter = tie %header, 'Blosxom::Header::Adapter', $blosxom::header;
        return $instance = bless \do { my $anon_scalar }, $class;
    }

    croak( q{$blosxom::header hasn't been initialized yet} );
}

sub has_instance { $instance }

sub is_initialized { ref $blosxom::header eq 'HASH' }

sub as_hashref { \%header }
sub boolify { 1 }

sub get {
    my ( $self, @fields ) = @_;
    @header{ @fields };
}

sub set {
    my ( $self, %new_header ) = @_;
    @header{ keys %new_header } = values %new_header; # merge!
    return;
}

sub delete {
    my ( $self, @fields ) = @_;
    delete @header{ @fields };
}

sub exists {
    my ( $self, $field ) = @_;
    exists $header{ $field };
}

sub clear { %header = () }

sub field_names { $adapter->field_names }

sub each {
    my ( $self, $callback ) = @_;

    if ( ref $callback eq 'CODE' ) {
        for my $field ( $adapter->field_names ) {
            $callback->( $field, $header{ $field } );
        }
    }
    elsif ( defined wantarray ) {
        return $self->_each;
    }
    else {
        croak( 'Must provide a code reference to each()' );
    }

    return;
}

# This method is deprecated and will be remove in 0.06
my %iterator;
sub _each {
    my $self = shift;

    if ( $iterator{is_exhausted} or !%iterator ) {
        my @fields = $adapter->field_names;
        %iterator = (
            collection => \@fields,
            size       => scalar @fields,
            current    => 0,
        );
    }

    if ( $iterator{current} < $iterator{size} ) {
        my $field = $iterator{collection}[ $iterator{current}++ ];
        return wantarray ? ( $field, $header{ $field } ) : $field;
    }
    else {
        $iterator{is_exhausted}++;
    }

    return;
}

sub is_empty { not %header }

sub flatten {
    my $self = shift;
    map { $_, $header{$_} } $adapter->field_names;
}

sub set_cookie {
    my ( $self, $name, $value ) = @_;

    require CGI::Cookie;

    my $new_cookie = CGI::Cookie->new(do {
        my %args = ref $value eq 'HASH' ? %{ $value } : ( value => $value );
        $args{name} = $name;
        \%args;
    });

    my @cookies;
    my $offset = 0;
    if ( my $cookies = $header{Set_Cookie} ) {
        @cookies = ref $cookies eq 'ARRAY' ? @{ $cookies } : $cookies;
        for my $cookie ( @cookies ) {
            last if ref $cookie eq 'CGI::Cookie' and $cookie->name eq $name;
            $offset++;
        }
    }

    # add/overwrite CGI::Cookie object
    splice @cookies, $offset, 1, $new_cookie;

    $header{Set_Cookie} = @cookies > 1 ? \@cookies : $cookies[0];

    return;
}

sub get_cookie {
    my ( $self, $name ) = @_;

    my @values;
    if ( my $cookies = $header{Set_Cookie} ) {
        @values = grep {
            ref $_ eq 'CGI::Cookie' and $_->name eq $name
        } (
            ref $cookies eq 'ARRAY' ? @{ $cookies } : $cookies,
        );
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

sub push_p3p_tags {
    my $self = ref $_[0] ? shift : __PACKAGE__->instance;
    $self->_push( P3P => @_ );
}

*push_p3p = \&push_p3p_tags;

sub _push {
    my ( $self, $field, @values ) = @_;

    return carp( 'Useless use of _push() with no values' ) unless @values;

    if ( my $value = $header{ $field } ) {
        return push @{ $value }, @values if ref $value eq 'ARRAY';
        unshift @values, $value;
    }

    $header{ $field } = @values > 1 ? \@values : $values[0];

    scalar @values;
}

sub attachment {
    my $self = shift;
    $adapter->attachment( @_ );
}

sub nph {
    my $self = shift;
    $adapter->nph( @_ );
}

sub charset {
    my $self = shift;
    my $type = $header{Content_Type};
    my ( $charset ) = $type =~ /charset=([^;]+)/ if $type;
    return unless $charset;
    uc $charset;
}

# This method is obsolete and will be removed in 0.06
sub cookie {
    my $self = shift;

    if ( @_ ) {
        delete $header{Set_Cookie};
        $self->push_cookie( @_ );
    }
    elsif ( my $cookie = $header{Set_Cookie} ) {
        my @cookies = ref $cookie eq 'ARRAY' ? @{ $cookie } : ( $cookie );
        return wantarray ? @cookies : $cookies[0];
    }

    return;
}

sub last_modified { shift->_date_header( Last_modified => $_[0] ) }
sub date          { shift->_date_header( Date => $_[0] )          }

sub _date_header {
    my ( $self, $field, $time ) = @_;

    if ( defined $time ) {
        return $header{ $field } = _time2str( $time );
    }
    elsif ( my $date = $header{ $field } ) {
        return _str2time( $date );
    }

    return;
}

sub expires {
    my $self = shift;
    return $header{Expires} = shift if @_;
    my $expires = $header{Expires};
    return unless $expires;
    _str2time( $expires );
}

sub p3p_tags {
    my $self = shift;

    if ( @_ ) {
        my @tags = @_ > 1 ? @_ : split / /, shift;
        $header{P3P} = @tags > 1 ? \@tags : $tags[0];
    }
    elsif ( my $tags = $header{P3P} ) {
        my @tags = ref $tags eq 'ARRAY' ? @{ $tags } : ( $tags );
        @tags = map { split / / } @tags;
        return wantarray ? @tags : $tags[0];
    }

    return;
}

*p3p = \&p3p_tags;

sub content_type {
    my $self = shift;
    return $header{Content_Type} = shift if @_;
    my $content_type = $header{Content_Type};
    return q{} unless $content_type;
    my ( $type, $rest ) = split /;\s*/, $content_type, 2;
    wantarray ? ( lc $type, $rest ) : lc $type;
}

*type = \&content_type;

sub status {
    my $self = shift;

    if ( @_ ) {
        require HTTP::Status;
        my $code = shift;
        my $message = HTTP::Status::status_message( $code );
        return $header{Status} = "$code $message" if $message;
        carp( qq{Unknown status code "$code" passed to status()} );
    }
    elsif ( my $status = $header{Status} ) {
        return substr( $status, 0, 3 );
    }

    return;
}

sub target {
    my $self = shift;
    return $header{Window_Target} = shift if @_;
    $header{Window_Target};
}

1;

__END__

=head1 NAME

Blosxom::Header - Object representing CGI response headers

=head1 SYNOPSIS

  use Blosxom::Header;

  my $header = Blosxom::Header->instance;

  my $status = $header->get( 'Status' ); # 304 Not Modified

  $header->set(
      Content_Length => 12345,
      Last_Modified  => 'Wed, 23 Sep 2009 13:36:33 GMT',
  );

=head1 DESCRIPTION

This module provides Blosxom plugin developers
with an interface to handle L<CGI> response headers.
Blosxom starts speaking HTTP at last.

=head2 BACKGROUND

Blosxom, an weblog application, globalizes C<$header> which is a hash reference.
This application passes C<$header> to C<CGI::header()> to generate
CGI response headers.

Blosxom plugins may modify C<$header> directly because the variable is
global.
The problem is that there is no agreement with how to normalize C<keys>
of C<$header>.
This module standardizes this process and also provides some convenience
methods.

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

  # field names are case-insensitive
  $header->get( 'Content-Length' );
  $header->get( 'Content_length' );

=item $header->set( $field => $value )

=item $header->set( $f1 => $v1, $f2 => $v2, ... )

Sets the value of one or more header fields.
Accepts a list of named arguments.

The $value argument must be a plain string, except for when the Set-Cookie
header is specified.
In an exceptional case, $value may be a reference to an array.

  use CGI::Cookie;

  my $cookie1 = CGI::Cookie->new( -name => 'foo' );
  my $cookie2 = CGI::Cookie->new( -name => 'bar' );

  $header->set( Set_Cookie => [ $cookie1, $cookie2 ] );

=item $bool = $header->exists( $field )

Returns a Boolean value telling whether the specified HTTP header exists.

  if ( $header->exists( 'ETag' ) ) {
      ....
  }

=item @deleted = $header->delete( @fields )

Deletes the specified fields from HTTP headers.
Returns values of deleted fields.

  $header->delete( qw/Content-Type Content-Length Content-Disposition/ );

=item $header->clear

This will remove all header fields.

  $header->clear;

Internally, this method is a shortcut for

  %{ $blosxom::header } = ( -type => q{} );

=item @fields = $header->field_names

Returns the list of distinct names for the fields present in the header.
The field names have case as returned by C<CGI::header()>.

  my @fields = $header->field_names;
  # => ( 'Set-Cookie', 'Content-length', 'Content-Type' )

In scalar context return the number of distinct field names.

  if ( $header->field_names == 0 ) {
      # no header fields
  }

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

This feature is obsolete and will disappear in 0.06.

=item $bool = $header->is_empty

Returns a Boolean value telling whether C<< $header->field_names >>
returns a null array or not.

  $header->clear;
  my $is_empty = $header->is_empty; # true

=item @headers = $header->flatten

Returns pairs of fields and values.

  my @headers = $header->flatten;
  # => ( 'Status', '304 Not Modified', 'Content-Type', 'text/plain' )

=item $header->as_hashref

=back

=head3 HANDLING COOKIES

C<cookie()> and C<push_cookie()> are obsolete and will be removed in 0.06.
These methods were replaced with C<set_cookie()> and C<get_cookie()>.

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

=item $header->cookie

This method is obsolete and will be removed in 0.06.
Use C<< $header->get_cookie >> or C<< $header->set_cookie >> instead.

=item $header->push_cookie( @cookies )

This method is obsolete and will be removed in 0.06.
Use C<< $header->set_cookie >> instead.

  use CGI::Cookie;

  my $cookie = CGI::Cookie->new(
      -name  => 'ID',
      -value => 123456,
  );

  $header->push_cookie( $cookie );

  # become

  $header->set_cookie( ID => 123456 );

=back

=head3 DATE HEADERS

These methods always convert their value to system time
(seconds since Jan 1, 1970).

=over 4

=item $mtime = $header->date

=item $header->date( $mtime )

This header represents the date and time at which the message
was originated. This method expects machine time when the header
value is set.

  $header->date( time ); # set current date

=item $mtime = $header->expires

=item $header->expires( $mtime )

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

=item $mtime = $header->last_modified

=item $header->last_modified( $mtime )

This header indicates the date and time at which the resource was
last modified. This method expects machine time when the header value is set.

  # check if document is more than 1 hour old
  if ( my $last_modified = $header->last_modified ) {
      if ( $last_modified < time - 60 * 60 ) {
          ...
      }
  }

=back

=head3 CONVENIENCE METHODS

The following methods were named after parameters recognized by
C<CGI::header()>.
These can both be used to read and to set the value of a header.
The value is set if you pass an argument to the method.
If the given header wasn't defined then C<undef> would be returned.

=over 4

=item $header->attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $header->attachment( 'genome.jpg' );
  my $attachment = $header->attachment; # genome.jpg

  my $disposition = $header->get( 'Content-Disposition' );
  # => 'attachment; filename="genome.jpg"'

=item $charset = $header->charset

Returns the upper-cased character set specified in the Content-Type header.

  $header->content_type( 'text/plain; charset=utf-8' );
  my $charset = $header->charset; # UTF-8

This method doesn't receive any arguments.

  # wrong
  $header->charset( 'euc-jp' );

=item $media_type = $header->content_type

=item ( $media_type, $rest ) = $header->content_type

=item $header->content_type( 'text/html; charset=ISO-88591' )

Represents the Content-Type header which indicates the media type of
the message content. C<type()> is an alias.

  $header->content_type( 'text/plain; charset=utf-8' );

The value returned will be converted to lower case, and potential parameters
will be chopped off and returned as a separate value if in an array context.

  my $type = $header->content_type; # 'text/plain'
  my @type = $header->content_type; # ( 'text/plain', 'charset=utf-8' )

If there is no such header field, then the empty string is returned.
This makes it safe to do the following:

  if ( $header->content_type eq 'text/html' ) {
      ...
  }

=item $header->nph

If set to a true value,
will issue the correct headers to work with
a NPH (no-parse-header) script:

  $header->nph( 1 );

=item @tags = $header->p3p_tags

=item $header->p3p_tags( @tags )

Represents the P3P tags. C<p3p()> is an alias.
The parameter can be an array or a space-delimited string.

  $header->p3p( qw/CAO DSP LAW CURa/ );
  $header->p3p( 'CAO DSP LAW CURa' );

  my @tags = $header->p3p; # ( 'CAO', 'DSP', 'LAW', 'CURa' )

In this case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"

=item @tags = $header->push_p3p_tags

=item $header->push_p3p_tags( @tags )

Adds P3P tags to the P3P header.
C<push_p3p()> is an alias.
Accepts a list of P3P tags.

  # get P3P tags
  my @tags = $header->p3p; # ( 'CAO', 'DSP', 'LAW' )

  # add P3P tags
  $header->push_p3p( 'CURa' );

  @tags = $header->p3p; # ( 'CAO', 'DSP', 'LAW', 'CURa' )

=item $code = $header->status

=item $header->status( $code )

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

=back

=head2 FUNCTIONS

The following functions are exported on demand.

=over 4

=item @values = header_get( @fields )

A shortcut for

  @values = Blosxom::Header->instance->get( @fields );

=item header_set( $field => $value )

=item header_set( $f1 => $v2, $f2 => $v2, ... )

A shorcut for

  Blosxom::Header->instance->set( $field => $value );
  Blosxom::Header->instance->set( $f1 => $v1, $f2 => $v2, ... );

=item $bool = header_exists( $field )

A shortcut for

  $bool = Blosxom::Header->instance->exists( $field );

=item @deleted = header_delete( @fields )

A shorcut for

  @deleted = Blosxom::Header->instance->delete( @fields );

=item push_cookie( @cookies )

This function is obsolete and will be removed in 0.06.
See L<"HANDLING COOKIES">.

=item push_p3p( @tags )

A shorcut for

  Blosxom::Header->instance->push_p3p( @tags );

=item header_iter( \&callback )

A shortcut for 

    Blosxom::Header->instance->each( \&callback );

E.g.:

  header_iter sub {
      my ($field, $value) = @_;
      print "$field: $value";
  };

  # wrong
  my $field = header_iter();
  my ( $field, $value ) = header_iter();

=item each_header( CodeRef )

=item $field = each_header()

=item ( $field, $value ) = each_header()

This function is obsolete and will be removed in 0.06.
Use C<header_iter()> instead.

=item header_push()

This function is obsolete and will be removed in 0.06.

=back

=head1 LIMITATIONS

Each header field is restricted to appear only once,
except for the Set-Cookie header.
That's why C<$header> can't C<push()> header fields unlike L<HTTP::Headers>
objects. This feature originates from how C<CGI::header()> behaves.

=head2 THE P3P HEADER

C<CGI::header()> restricts where the policy-reference file is located
and so you can't modify the location (C</w3c/p3p.xml>).
The subroutine outputs the P3P header in the following format:

  P3P: policyref="/w3c/p3p.xml" CP="%s"

therefore the following code doesn't work correctly:

  # wrong
  $header->set( P3P => q{policyref="/path/to/p3p.xml"} );
  $header->p3p( q{policyref="/path/to/p3p.xml"} );

You're allowed to set or add P3P tags by using C<< $header->p3p_tags >>
or C<< $header->push_p3p_tags >>.

=head2 THE DATE HEADER

C<CGI::header()> fixes the Date header when any of
C<< $header->get( 'Set-Cookie' ) >>,
C<< $header->expires >> or C<< $header->nph >> returns true. 
When the Date header is fixed, you can't modify the value:

  $header->set_cookie( ID => 123456 );
  # => CGI::header() fixes the Date header

  my $bool = $header->date == CORE::time(); # true

  # wrong
  $header->date( $time );
  $header->set( Date => $date );

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

=head1 BUGS

There are no known bugs in this module.
Please report problems to ANAZAWA (anazawa@cpan.org).
Patches are welcome.

=head1 MAINTAINER

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

