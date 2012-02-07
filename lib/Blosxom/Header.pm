package Blosxom::Header;
use strict;
use warnings;

our $VERSION = '0.01012';

sub new {
    my $class   = shift;
    my $headers = shift;

    bless { headers => $headers }, $class;
}

sub get {
    my $self    = shift;
    my $key     = _lc(shift);
    my $headers = $self->{headers};

    my @keys   = grep { $key eq _lc($_) } keys %$headers;
    my @values = @{$headers}{@keys};

    wantarray ? @values : $values[0];
}

sub set {
    my $self    = shift;
    my $key     = shift;
    my $value   = shift;
    my $headers = $self->{headers};

    my $set;
    for (keys %$headers) {
        next unless _lc($key) eq _lc($_);
        $headers->{$_} = $value;
        $set++;
        last;
    } 

    $headers->{$key} = $value unless $set;

    return;
}

sub exists {
    my $self = shift;
    my $key  = _lc(shift);

    # any
    for (keys %{$self->{headers}}) {
        return 1 if _lc($_) eq $key;
    } 

    return;
}

sub remove {
    my $self    = shift;
    my $key     = _lc(shift);
    my $headers = $self->{headers};

    my @keys = grep { _lc($_) eq $key } keys %$headers;
    delete @{$headers}{@keys};

    return;
}

sub _lc {
    my $key = lc shift;
    $key =~ s{^\-}{};
    $key;
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

  my $h = Blosxom::Header->new($blosxom::header);
  my $value = $h->get($key);
  my $bool = $h->exists($key);

  $h->set($key, $value); # overwrites existent header
  $h->remove($key);

  $h->{headers}; # same reference as $blosxom::header

=head1 DESCRIPTION

Blosxom, a weblog application, exports a global variable $header
which is a reference to hash. This application passes $header L<CGI>::header()
to generate HTTP headers.

When plugin developers modify HTTP headers, they must write as follows:

  package foo;
  $blosxom::header->{'-status'} = '304 Not Modified';

It's obviously bad practice. Blosxom misses the interface to modify
them.  

This module allows you to modify them in an object-oriented way:

  my $h = Blosxom::Header->new($blosxom::header);
  $h->set(Status => '304 Not Modified');

You don't have to care whether to put a hyphen before a key,
and also whether to make a key lowercased or L<camelized|String::CamelCase>.
And so the following forms are semantically identical:

=over 4

=item status

=item -status

=item Status

=item -Status

=back

=head2 METHODS

=over 4

=item $h = Blosxom::Header->new($headers);

Creates a new Blosxom::Header object.
The object holds a reference to the original given $headers argument.

=item $h->get('foo')

Returns a value of the specified HTTP header.

=item $h->exists('foo')

Returns a Boolean value telling whether the specified HTTP header exists.

=item $h->set('foo' => 'bar')

Sets a value of the specified HTTP header.

=item $h->remove('foo')

Deletes the specified element from HTTP headers.

=back

=head2 RECOGNIZED PARAMETERS

Refer to L<CGI>::header.

=over 4

=item type

Represents the Content-Type header.

  $h->set(type => 'text/plain')

=item nph

If set to a true value, will issue the correct headers to work with
a NPH (no-parse-header) script.

  $h->set(nph => 1)

=item expires

Represents the Expires header.
You can specify an absolute or relative expiration interval.
The following forms are all valid for this field.

  $h->set(expires => '+30s') # 30 seconds from now
  $h->set(expires => '+10m') # ten minutes from now
  $h->set(expires => '+1h')  # one hour from now
  $h->set(expires => '-1d')  # yesterday
  $h->set(expires => 'now')  # immediately
  $h->set(expires => '+3M')  # in three months
  $h->set(expires => '+10y') # in ten years time

  # at the indicated time & date
  $h->set(expires => 'Thu, 25 Apr 1999 00:40:33 GMT')

=item cookie

Represents the Set-Cookie header.
The parameter can be an arrayref or a string.

  $h->set(cookie => ['foo=bar', 'bar=baz']);
  $h->set(cookie => 'foo=bar')

=item charset

Represents the character set sent to the browser.
If not provided, defaults to ISO-8859-1.

  $h->set(charset => 'utf-8')

=item attachment

Can be used to turn the page into an attachment.
Represents suggested name for the saved file.

  $h->set(attachment => 'foo.png')

=item p3p

Will add a P3P tag to the outgoing header.
The parameter can be arrayref or a space-delimited string.

  $h->set(p3p => [qw(CAO DSP LAW CURa)])
  $h->set(p3p => 'CAO DSP LAW CURa')

In either case, the outgoing header will be formatted as:

  P3P: policyref="/w3c/p3p.xml" cp="CAO DSP LAW CURa"

=back

=head1 EXAMPLES

The following code is a Blosxom plugin to enable conditional GET and HEAD using
C<If-None-Match> and C<If-Modified-Since> headers.
Refer to L<Plack::Middleware::ConditionalGET>.

plugins/conditional_get:

  package conditional_get;
  use strict;
  use warnings;
  use Blosxom::Header;

  sub start { !$blosxom::static_entries }

  sub last {
      return unless $ENV{REQUEST_METHOD} =~ /^(GET|HEAD)$/;

      my $h = Blosxom::Header->new($blosxom::header);
      if (etag_matches($h) or not_modified_since($h)) {
          $h->set('Status' => '304 Not Modified');
          $h->remove($_) for qw(Content-Length attachment);

          # If the Content-Type header isn't defined,
          # CGI::header will add default value.
          # And so makes it defined.
          $h->set(type => q{});

          # Truncate output
          $blosxom::output = q{};
      }

      return;
  }

  sub etag_matches {
      my $h = shift;
      return unless $h->exists('ETag');
      $h->get('ETag') eq _value($ENV{HTTP_IF_NONE_MATCH});
  }

  sub not_modified_since {
      my $h = shift;
      return unless $h->exists('Last-Modified');
      $h->get('Last-Modified') eq _value($ENV{HTTP_IF_MODIFIED_SINCE});
  }

  sub _value {
      my $str = shift;
      $str =~ s{;.*$}{};
      $str;
  }
  
  1;

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
