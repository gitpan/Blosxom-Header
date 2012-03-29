package Blosxom::Header;
use 5.008_001;
use strict;
use warnings;
use Carp;
use Exporter 'import';

our $VERSION   = '0.02003';
our @EXPORT_OK = qw( get_header set_header push_cookie delete_header exists_header );

# the alias of Blosxom::Header::Object->new
sub new {
    require Blosxom::Header::Object;
    Blosxom::Header::Object->new( $_[1] );
}

sub get_header {
    my $header_ref = shift;
    my $key        = _norm( shift );

    my @values;
    while ( my ( $k, $v ) = each %{ $header_ref } ) {
        push @values, $v if $key eq _norm( $k );
    }

    return unless @values;
    carp "Multiple elements specify the $key header." if @values > 1;

    my $value = shift @values;
    return $value unless ref $value eq 'ARRAY';
    wantarray ? @{ $value } : $value->[0];
}

sub delete_header {
    my $header_ref = shift;
    my $key        = _norm( shift );

    # deletes elements whose key matches $key
    my @keys = grep { _norm( $_ ) eq $key } keys %{ $header_ref };
    delete @{ $header_ref }{ @keys };

    return;
}

sub set_header {
    my $header_ref = shift;
    my $key        = _norm( shift );
    my $value      = shift;

    delete_header( $header_ref, $key );
    $header_ref->{ $key } = $value;

    return;
}

sub exists_header {
    my $header_ref = shift;
    my $key        = _norm( shift );

    my $exists = 0;
    for my $k ( keys %{ $header_ref } ) {
        $exists++ if _norm( $k ) eq $key;
    }

    carp "$exists elements specify the $key field." if $exists > 1;
    $exists;
}

sub push_cookie {
    my ( $header_ref, $cookie ) = @_;
    my @cookies = get_header( $header_ref, 'cookie' ) || ();
    push @cookies, $cookie;
    set_header( $header_ref, 'cookie' => \@cookies );
    return;
}

{
    # suppose read-only
    my %alias_of = (
        'content-type' => 'type',
        'set-cookie'   => 'cookie',
    );

    # normalize a given key
    sub _norm {
        my $key = lc shift;

        # get rid of an initial dash if exists
        $key =~ s{^\-}{};

        # use dashes instead of underscores
        $key =~ tr{_}{-};

        # returns the alias of $key if exists
        $alias_of{ $key } || $key;
    }
}

1;

__END__

=head1 NAME

Blosxom::Header - Missing interface to modify HTTP headers

=head1 SYNOPSIS

  use Blosxom::Header qw(
      get_header
      set_header
      delete_header
      exists_header
      push_cookie
  );

  # Procedural interface

  my $value = get_header( $blosxom::header, 'foo' );
  my $bool  = exists_header( $blosxom::header, 'foo' );

  set_header( $blosxom::header, foo => 'bar' );
  delete_header( $blosxom::header, 'foo' );

  my @cookies = get_header( $blosxom::header, 'Set-Cookie' );
  push_cookie( $blosxom::header, 'foo' );

  # Object-oriented interface

  my $h     = Blosxom::Header->new( $blosxom::header );
  my $value = $h->get( 'foo' );
  my $bool  = $h->exists( 'foo' );

  $h->set( foo => 'bar' );
  $h->delete( 'foo' );

  my @cookies = $h->get( 'Set-Cookie' );
  $h->push_cookie( 'foo' );

  $h->header; # same reference as $blosxom::header

=head1 DESCRIPTION

Blosxom, a weblog application, exports a global variable $header
which is a reference to hash.
This application passes $header L<CGI>::header() to generate
HTTP headers.

When plugin developers modify HTTP headers, they must write as follows:

  package foo;
  $blosxom::header->{'-status'} = '304 Not Modified';

It's obviously bad practice.
Multiple elements may specify the same field:

  $blosxom::header->{'-status'} = '304 Not Modified';
  $blosxom::header->{'status' } = '304 Not Modified';
  $blosxom::header->{'-Status'} = '304 Not Modified';
  $blosxom::header->{'Status' } = '304 Not Modified';

Blosxom misses the interface to modify HTTP headers.

=head2 SUBROUTINES

The following are exported on demand.

=over 4

=item $value = get_header( $blosxom::header, 'foo' )

Returns a value of the specified HTTP header.

=item @cookies = get_header( $blosxom::header, 'Set-Cookie' )

Returns values of the Set-Cookie headers.

=item set_header( $blosxom::header, 'foo' => 'bar' )

Sets a value of the specified HTTP header.

=item $bool = exists_header( $blosxom::header, 'foo' )

Returns a Boolean value telling whether the specified HTTP header exists.

=item delete_header( $blosxom::header, 'foo' )

Deletes all the specified elements from HTTP headers.

=item push_cookie( $blosxom::header, 'foo' )

Pushes the Set-Cookie header onto HTTP headers.

=back

=head2 METHODS

=over 4

=item $h = Blosxom::Header->new( $blosxom::header )

Creates a new Blosxom::Header object.
Must pass a reference to hash.

=item $bool = $h->exists( 'foo' )

A synonym for exists_header.

=item $value = $h->get( 'foo' )

=item @cookies = $h->get( 'Set-Cookie' )

A synonym for get_header.

=item $h->delete( 'foo' )

A synonym for delete_header.

=item $h->set( 'foo' => 'bar' )

A synonym for set_header.

=item $h->push_cookie( 'foo' )

A synonym for push_cookie.

=item $h->header

Returns the same reference as $blosxom::header.

=back

=head1 EXAMPLES

L<CGI>::header recognizes the following parameters.

=over 4

=item attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $h->set( attachment => 'foo.png' );

In this case, the outgoing header will be formatted as:

  Content-Disposition: attachment; filename="foo.png"

=item charset

Represents the character set sent to the browser.
If not provided, defaults to ISO-8859-1.

  $h->set( charset => 'utf-8' );

=item cookie

Represents the Set-Cookie headers.
The parameter can be an arrayref or a string.

  $h->set( cookie => [$cookie1, $cookie2] );
  $h->set( cookie => $cookie );

Refer to L<CGI>::cookie.

=item expires

Represents the Expires header.
You can specify an absolute or relative expiration interval.
The following forms are all valid for this field.

  $h->set( expires => '+30s' ); # 30 seconds from now
  $h->set( expires => '+10m' ); # ten minutes from now
  $h->set( expires => '+1h'  ); # one hour from now
  $h->set( expires => '-1d'  ); # yesterday
  $h->set( expires => 'now'  ); # immediately
  $h->set( expires => '+3M'  ); # in three months
  $h->set( expires => '+10y' ); # in ten years time

  # at the indicated time & date
  $h->set( expires => 'Thu, 25 Apr 1999 00:40:33 GMT' );

=item nph

If set to a true value,
will issue the correct headers to work with
a NPH (no-parse-header) script:

  $h->set( nph => 1 );

=item p3p

Will add a P3P tag to the outgoing header.
The parameter can be an arrayref or a space-delimited string.

  $h->set( p3p => [qw(CAO DSP LAW CURa)] );
  $h->set( p3p => 'CAO DSP LAW CURa' );

In either case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" CP="CAO DSP LAW CURa"

=item type

Represents the Content-Type header.

  $h->set( type => 'text/plain' );

=back

=head1 DEPENDENCIES

L<Blosxom 2.1.2|http://blosxom.sourceforge.net/>

=head1 SEE ALSO

L<CGI>

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
