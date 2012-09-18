package Blosxom::Header;
use 5.008_009;
use strict;
use warnings;
use parent 'Blosxom::Header::Entity';
use Exporter 'import';
use Carp qw/croak/;

our $VERSION = '0.06003';

our @EXPORT_OK = qw(
    header_get    header_set  header_exists
    header_delete header_iter
);

sub header_get    { __PACKAGE__->instance->get( @_ )    }
sub header_set    { __PACKAGE__->instance->set( @_ )    }
sub header_exists { __PACKAGE__->instance->exists( @_ ) }
sub header_delete { __PACKAGE__->instance->delete( @_ ) }
sub header_iter   { __PACKAGE__->instance->each( @_ )   }

our $INSTANCE;

sub new { croak "Private method 'new' called for $_[0]" }

sub is_initialized { ref $blosxom::header eq 'HASH' }

sub has_instance { $INSTANCE }

sub instance {
    my $class = shift;

    return $class    if ref $class;
    return $INSTANCE if defined $INSTANCE;

    if ( ref $blosxom::header eq 'HASH' ) {
        return $INSTANCE = $class->SUPER::new( $blosxom::header );
    }

    croak "$class hasn't been initialized yet";
}

1;

__END__

=head1 NAME

Blosxom::Header - Object representing CGI response headers

=head1 SYNOPSIS

  use Blosxom::Header;

  my $header = Blosxom::Header->instance;

  $header->set( Content_Length => 12345 );
  my $value   = $header->get( 'Status' );
  my $deleted = $header->delete( 'Content-Disposition' );
  my $bool    = $header->exists( 'ETag' );

  # as a hash reference
  $header->{Content_Length} = 12345;
  my $value   = $header->{Status};
  my $deleted = delete $header->{Content_Disposition};
  my $bool    = exists $header->{ETag};

  # procedural interface
  use Blosxom::Header qw(
      header_get    header_set
      header_exists header_delete
  );

  header_set( Content_Length => 12345 );
  my $value   = header_get( 'Status' );
  my $deleted = header_delete( 'Content-Disposition' );
  my $bool    = header_exists( 'ETag' );

=head1 DESCRIPTION

This module provides Blosxom plugin developers
with an interface to handle L<CGI> response headers.
This class represents a global variable C<$blosxom::header>,
and so it can have only one instance.
Since the variable is a reference to a hash, each header field is
restricted to appear only once except the C<Set-Cookie> header.
In other words, the instance behaves like a hash rather than an array.

=head2 BACKGROUND

Blosxom, an weblog application, globalizes C<$header> which is a hash reference.
This application passes C<$header> to C<CGI::header()> to generate
CGI response headers.

Blosxom plugins may modify C<$header> directly because the variable is
global.
The problem is that there is no agreement with how to normalize C<keys>
of C<$header>.
If we normalized them, plugins would be compatible with each other.

In addition, C<CGI::header()> doesn't behave intuitively.
It's difficult for us to predict what the subroutine will return
unless we execute it.
Although CGI's pod tells us how it will work,
it's painful for lazy people to reread the document
whenever they manipulate CGI response headers.
It lowers their productivity.
While it's easy to replace CGI.pm with other modules,
this module extends Blosxom without rewriting C<blosxom.cgi>.

=head2 CLASS METHODS

=over 4

=item $header = Blosxom::Header->instance

Returns a current Blosxom::Header object instance or create a new one.

C<new()> isn't an alias, any more. C<new()> become a private method
since 0.06003.

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
  $header->get( 'content_length' );

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

  if ( $header->exists('ETag') ) {
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

=item $header->each( \&callback )

Apply a subroutine to each header field in turn.
The callback routine is called with two parameters;
the name of the field and a value.
Any return values of the callback routine are ignored.

  $header->each(sub {
      my ( $field, $value ) = @_;
      ...
  });

=item $bool = $header->is_empty

Returns a Boolean value telling whether C<< $header->field_names >>
returns a null array or not.

  $header->clear;

  if ( $header->is_empty ) { # true
      ...
  }

=item @headers = $header->flatten

Returns pairs of fields and values.

  my @headers = $header->flatten;
  # => ( 'Status', '304 Not Modified', 'Content-Type', 'text/plain' )

=item $hashref = $header->as_hashref

Returns a reference to hash which represents header fields.
You can manipulate header fields using the hash syntax.

  $header->as_hashref->{Foo} = 'bar';
  my $value   = $header->as_hashref->{Foo};
  my $deleted = delete $header->as_hashref->{Foo};
  my $bool    = exists $header->as_hashref->{Foo};

Since the hash dereference operator of C<$header> is L<overload>ed
with C<as_hashref()>,
you can omit calling C<as_hashref()> method from the above operations:

  $header->{Foo} = 'bar';
  my $value   = $header->{Foo};
  my $deleted = delete $header->{Foo};
  my $bool    = exists $header->{Foo};

NOTE: You can't iterate over C<$header> using C<CORE::each()>, C<CORE::keys()>
or C<CORE::values()>. Use C<< $header->field_names >> or C<< $header->each >>
instead.

  # not supported
  keys %{ $header };
  values %{ $header };
  each %{ $header };

=back

=head3 HANDLING COOKIES

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

  my $value   = $id->value;   # '123456'
  my $path    = $id->path;    # '/'
  my $domain  = $id->domain;  # '.example.com'
  my $expires = $id->expires; # 'Thu, 25 Apr 1999 00:40:33 GMT'

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

=item $filename = $header->attachment

=item $header->attachment( $filename )

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

=item $header->content_type( 'text/html; charset=ISO-8859-1' )

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

Represents the P3P tags.
The parameter can be an array or a space-delimited string.

  $header->p3p_tags( qw/CAO DSP LAW CURa/ );
  $header->p3p_tags( 'CAO DSP LAW CURa' );

  my @tags = $header->p3p_tags; # ( 'CAO', 'DSP', 'LAW', 'CURa' )

In this case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml", CP="CAO DSP LAW CURa"

=item $header->push_p3p_tags( @tags )

This method is obsolete and will be removed in 0.07.

Adds P3P tags to the P3P header.
Accepts a list of P3P tags.

  # get P3P tags
  my @tags = $header->p3p_tags; # ( 'CAO', 'DSP', 'LAW' )

  # add P3P tags
  $header->push_p3p_tags( 'CURa' );

  @tags = $header->p3p_tags; # ( 'CAO', 'DSP', 'LAW', 'CURa' )

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

=item header_iter( \&callback )

A shortcut for 

    Blosxom::Header->instance->each( \&callback );

=back

=head1 EXAMPLES

The following script is a Blosxom plugin which just adds the Content-Length
header to CGI response headers.

  package content_length;
  use strict;
  use warnings;
  use Blosxom::Header qw/header_set/;

  sub start { !$blosxom::static_entries }

  sub last { header_set( 'Content-Length' => length $blosxom::output ) }

  1;

=head1 LIMITATIONS

Each header field is restricted to appear only once,
except for the Set-Cookie header.
That's why C<$header> can't C<push()> header fields unlike L<HTTP::Headers>
objects. In other words, C<CGI::header()> behaves like a hash rather than
an array.

=head2 THE P3P HEADER

Since C<CGI::header()> restricts where the policy-reference file is located,
you can't modify the location (C</w3c/p3p.xml>).
The subroutine outputs the P3P header in the following format:

  P3P: policyref="/w3c/p3p.xml", CP="%s"

therefore the following code doesn't work as you expect:

  # wrong
  $header->set( P3P => q{policyref="/path/to/p3p.xml"} );

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

=item Unknown status code '%d%d%d' passed to status()

The given status code is unknown to L<HTTP::Status>.

=item The Date header is fixed

You attempted to C<set()> or C<delete()> the Date header
when the Date header was fixed. See L<"LIMITATIONS">.

=item Can't assign to '%s' directly, use accessors instead

You attempted to C<set()> the Expires or P3P header.
You can't assign any values to these headers directly.
Use L<expires()> or L<p3p_tags()> instead.

=back

=head1 DEPENDENCIES

L<Blosxom 2.0.0|http://blosxom.sourceforge.net/> or higher.

=head1 SEE ALSO

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

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

