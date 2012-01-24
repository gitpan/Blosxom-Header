package Blosxom::Header;
use strict;
use warnings;

our $VERSION   = '0.01008';

sub new {
    my $class   = shift;
    my $headers = shift;

    return bless { headers => $headers }, $class;
}

sub get {
    my $self    = shift;
    my $key     = _lc(shift);
    my $headers = $self->{headers};

    my $value;
    if ($key and exists $headers->{$key}) {
        $value = $headers->{$key};
    }

    return $value;
}

sub remove {
    my $self    = shift;
    my $key     = _lc(shift);
    my $headers = $self->{headers};

    if ($key and exists $headers->{$key}) {
        delete $headers->{$key};
    }

    return;
}

sub set {
    my $self  = shift;
    my $key   = _lc(shift);
    my $value = shift;

    if ($key) {
        $self->{headers}{$key} = $value;
    }

    return;
}

sub exists {
    my $self = shift;
    my $key  = _lc(shift);

    my $exists;
    if ($key) {
        $exists = exists $self->{headers}{$key};
    }

    return $exists;
}

sub _lc {
    my $key = shift;

    my $new_key;
    if ($key) {
        $key = lc $key;
        $new_key = $key eq 'content-type' ? '-type' :"-$key";
    }

    return $new_key;
}

1;

__END__

=head1 NAME

Blosxom::Header - Missing interface to modify HTTP headers

=head1 SYNOPSIS

  use Blosxom::Header;

  my $headers = { -type => 'text/html' };

  my $h = Blosxom::Header->new($headers);
  my $value = $h->get($key);
  my $bool = $h->exists($key);

  $h->set($key, $value); # overwrites existent header
  $h->remove($key);

  $h->{headers}; # same reference as $headers

=head1 DESCRIPTION

Blosxom, a weblog application, exports a global variable $header
which is a reference to hash. This application passes $header CGI::header()
to generate HTTP headers.

When plugin writers modify HTTP headers, they must write as follows:

  package foo;
  $blosxom::header->{'-type'} = 'text/plain';

It's obviously bad practice. Blosxom misses the interface to modify
them.  

This module allows you to modify them in an object-oriented way.
If loaded, you might write as follows:

  my $h = Blosxom::Header->new($blosxom::header);
  $h->set('Content-Type' => 'text/plain');

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

=head1 EXAMPLES

  # plugins/content_length
  package content_length;
  use Blosxom::Header;

  sub start {
      return $blosxom::static_or_dynamic eq 'dynamic' ? 1 : 0;
  }

  sub last {
      my $h = Blosxom::Header->new($blosxom::header);
      $h->set('Content-Length' => length $blosxom::output);
  }

=head1 DEPENDENCIES

L<Blosxom 2.1.2|http://blosxom.sourceforge.net/>

=head1 SEE ALSO

The interface of this module is inspired by L<Plack::Util>.

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ryo Anazawa. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

