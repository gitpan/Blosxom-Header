package Blosxom::Header;
use 5.008_001;
use strict;
use warnings;
use List::Util qw(first);

our $VERSION = '0.01013';

sub new {
    my ( $class, $header_ref ) = @_;
    bless { header_ref => $header_ref }, $class;
}

sub get {
    my $self       = shift;
    my $key        = _lc( shift );
    my $header_ref = $self->{header_ref};

    # if any key matches $key, return the value
    my $value;
    while ( my ( $k, $v ) = each %{ $header_ref } ) {
        next unless _lc( $k ) eq $key;
        $value = $v;
        last;
    }

    return $value;
}

sub set {
    my $self       = shift;
    my $key        = shift;
    my $value      = shift;
    my $header_ref = $self->{header_ref};

    # if any key matches $key, replaces the value with $value
    my $k = first { _lc( $_ ) eq _lc( $key ) } keys %{ $header_ref };
    $header_ref->{ $k || $key } = $value;

    return;
}

sub exists {
    my $self   = shift;
    my $key    = _lc( shift );
    my $exists = 0;

    # if any key matches $key, returns true
    for my $k ( keys %{ $self->{header_ref} } ) {
        next unless _lc( $k ) eq $key;
        $exists = 1;
        last;
    }

    return $exists;
}

sub remove {
    my $self       = shift;
    my $key        = _lc( shift );
    my $header_ref = $self->{header_ref};

    # deletes an element whose key matches $key
    my @keys = grep { _lc( $_ ) eq $key } keys %{ $header_ref };
    delete @{ $header_ref }{ @keys };

    return;
}

# returns a lowercased version of a given string
sub _lc {
    my $key = lc shift;

    # get rid of an initial hyphen if exists
    $key =~ s{^\-}{};

    # use hyphens instead of underbars
    $key =~ tr{_}{-};

    return $key;
}

1;

__END__

=head1 NAME

Blosxom::Header - Missing interface to modify HTTP headers

=head1 SYNOPSIS

  # blosxom.cgi
  package blosxom;
  our $header = { -type => 'text/html' };

  # plugins/foo
  package foo;
  use Blosxom::Header;

  my $h     = Blosxom::Header->new($blosxom::header);
  my $value = $h->get('type');
  my $bool  = $h->exists('type');

  $h->set( type => 'text/plain' );
  $h->remove('type');

=head1 DESCRIPTION

Blosxom, a weblog application, exports a global variable $header
which is a reference to hash.
This application passes $header L<CGI>::header() to generate
HTTP headers.

When plugin developers modify HTTP headers, they must write as follows:

  package foo;
  $blosxom::header->{'-status'} = '304 Not Modified';

It's obviously bad practice.
Blosxom misses the interface to modify them.

This module allows you to modify them in an object-oriented way:

  my $h = Blosxom::Header->new($blosxom::header);
  $h->set(Status => '304 Not Modified');

You don't need to mind whether to put a hyphen before a key,
nor whether to make a key lowercased or L<camelized|String::CamelCase>.

=head2 METHODS

=over 4

=item $h = Blosxom::Header->new($blosxom::header)

Creates a new Blosxom::Header object.

=item $h->exists('foo')

Returns a Boolean value telling whether the specified HTTP header exists.

=item $h->get('foo')

Returns a value of the specified HTTP header.

=item $h->remove('foo')

Deletes the specified element from HTTP headers.

=item $h->set('foo' => 'bar')

Sets a value of the specified HTTP header.

=back

=head1 EXAMPLES

L<CGI>::header recognizes the following parameters.

=over 4

=item attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $h->set(attachment => 'foo.png');

In this case, the outgoing header will be formatted as:

  Content-Disposition: attachment; filename="foo.png"

=item charset

Represents the character set sent to the browser.
If not provided, defaults to ISO-8859-1.

  $h->set(charset => 'utf-8');

=item cookie

Represents the Set-Cookie header.
The parameter can be an arrayref or a string.

  $h->set(cookie => [$cookie1, $cookie2]);
  $h->set(cookie => $cookie);

Refer to L<CGI>::cookie.

=item expires

Represents the Expires header.
You can specify an absolute or relative expiration interval.
The following forms are all valid for this field.

  $h->set(expires => '+30s'); # 30 seconds from now
  $h->set(expires => '+10m'); # ten minutes from now
  $h->set(expires => '+1h' ); # one hour from now
  $h->set(expires => '-1d' ); # yesterday
  $h->set(expires => 'now' ); # immediately
  $h->set(expires => '+3M' ); # in three months
  $h->set(expires => '+10y'); # in ten years time

  # at the indicated time & date
  $h->set(expires => 'Thu, 25 Apr 1999 00:40:33 GMT');

=item nph

If set to a true value,
will issue the correct headers to work with
a NPH (no-parse-header) script:

  $h->set(nph => 1);

=item p3p

Will add a P3P tag to the outgoing header.
The parameter can be an arrayref or a space-delimited string.

  $h->set(p3p => [qw(CAO DSP LAW CURa)]);
  $h->set(p3p => 'CAO DSP LAW CURa');

In either case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" cp="CAO DSP LAW CURa"

=item type

Represents the Content-Type header.

  $h->set(type => 'text/plain');

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
