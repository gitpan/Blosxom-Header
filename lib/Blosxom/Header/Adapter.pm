package Blosxom::Header::Adapter;
use strict;
use warnings;
use Carp qw/carp/;
use CGI::Util qw/expires/;

sub TIEHASH {
    my $class   = shift;
    my $adaptee = ref $_[0] eq 'HASH' ? shift : {};
    my $self    = bless { adaptee => $adaptee }, $class;

    $self->{norm_of} = {
        -attachment => q{},        -charset       => q{},
        -cookie     => q{},        -nph           => q{},
        -set_cookie => q{-cookie}, -target        => q{},
        -type       => q{},        -window_target => q{-target},
    };

    $self->{field_name_of} = {
        -attachment => 'Content-Disposition', -cookie => 'Set-Cookie',
        -target     => 'Window-Target',       -type   => 'Content-Type',
        -p3p        => 'P3P',
    };

    $self->{iterator} = {
        collection => [],
        current    => 0,
        size       => 0,
    };

    $self;
}

sub FETCH {
    my $self    = shift;
    my $norm    = $self->normalize( shift );
    my $adaptee = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        my $type    = $adaptee->{-type};
        my $charset = $adaptee->{-charset};

        if ( defined $type and $type eq q{} ) {
            undef $charset;
            undef $type;
        }
        elsif ( !defined $type ) {
            $type    = 'text/html';
            $charset = 'ISO-8859-1' unless defined $charset;
        }
        elsif ( $type =~ /\bcharset\b/ ) {
            undef $charset;
        }
        elsif ( !defined $charset ) {
            $charset = 'ISO-8859-1';
        }

        return $charset ? "$type; charset=$charset" : $type;
    }
    elsif ( $norm eq '-content_disposition' ) {
        my $attachment = $adaptee->{-attachment};
        return qq{attachment; filename="$attachment"} if $attachment;
    }
    elsif ( $norm eq '-expires' ) {
        my $expires = $adaptee->{ $norm };
        return $expires ? expires( $expires ) : undef;
    }
    elsif ( $norm eq '-date' and $self->has_date_header ) {
        return expires( 0, 'http' );
    }

    $adaptee->{ $norm };
}

*EXISTS = \&FETCH;

sub STORE {
    my $self    = shift;
    my $norm    = $self->normalize( shift );
    my $value   = shift;
    my $adaptee = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        my $has_charset = $value =~ /\bcharset\b/;
        delete $adaptee->{-charset} if $has_charset;
        $adaptee->{-charset} = q{} unless $has_charset;
        $norm = '-type';
    }
    elsif ( $norm eq '-content_disposition' ) {
        delete $adaptee->{-attachment};
    }
    elsif ( $norm eq '-date' and $self->has_date_header ) {
        carp( 'The Date header is fixed' );
        return;
    }

    $adaptee->{ $norm } = $value;

    return;
}

sub DELETE {
    my $self    = shift;
    my $norm    = $self->normalize( shift );
    my $adaptee = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        my $deleted = $self->FETCH( 'Content-Type' );
        delete $adaptee->{-charset};
        $adaptee->{-type} = q{};
        return $deleted;
    }
    elsif ( $norm eq '-content_disposition' ) {
        my $deleted = $self->FETCH( 'Content-Disposition' );
        delete @{ $adaptee }{ $norm, '-attachment' };
        return $deleted;
    }
    elsif ( $norm eq '-date' and $self->has_date_header ) {
        carp( 'The Date header is fixed' );
        return
    }

    delete $adaptee->{ $norm };
}

sub CLEAR {
    my $self = shift;
    %{ $self->{adaptee} } = ( -type => q{} );
}

sub FIRSTKEY {
    my $self    = shift;
    my $adaptee = $self->{adaptee};

    my @field_names;
    push @field_names, 'Content-Type' unless exists $adaptee->{-type};
    push @field_names, 'Date' if $self->has_date_header;
    for my $norm ( keys %{ $adaptee } ) {
        next unless $adaptee->{ $norm };
        next if $norm eq '-charset' or $norm eq '-nph';
        push @field_names, $self->denormalize( $norm );
    }

    %{ $self->{iterator} } = (
        collection => \@field_names,
        size       => scalar @field_names,
        current    => 0,
    );

    $self->NEXTKEY;
}

sub NEXTKEY {
    my $iterator = shift->{iterator};
    return if $iterator->{current} >= $iterator->{size};
    $iterator->{collection}->[ $iterator->{current}++ ];
}

sub SCALAR {
    my $self = shift;
    my $scalar = $self->FIRSTKEY;
    $self->{iterator}->{current}-- if $scalar;
    $scalar;
}

sub normalize {
    my $self    = shift;
    my $field   = lc shift;
    my $norm_of = $self->{norm_of};

    # transliterate dashes into underscores
    $field =~ tr{-}{_};

    # add an initial dash
    $field = "-$field";

    exists $norm_of->{ $field } ? $norm_of->{ $field } : $field;
}

sub denormalize {
    my $self = shift;
    my $norm = shift;
    my $field_name_of = $self->{field_name_of};

    return $field_name_of->{ $norm } if exists $field_name_of->{ $norm };
        
    # get rid of an initial dash
    ( my $field = $norm ) =~ s/^-//;

    # transliterate underscores into dashes
    $field =~ tr/_/-/;

    # uppercase the first character
    $field_name_of->{ $norm } = ucfirst $field;
}

sub attachment {
    my $adaptee = shift->{adaptee};
    return $adaptee->{-attachment} = shift if @_;
    $adaptee->{-attachment};
}

sub nph {
    my $adaptee = shift->{adaptee};
    return $adaptee->{-nph} = shift if @_;
    $adaptee->{-nph};
}

sub has_date_header {
    my $adaptee = shift->{adaptee};
    $adaptee->{-expires} || $adaptee->{-cookie} || $adaptee->{-nph};
}

1;

__END__

=head1 NAME

Blosxom::Header::Adapter - Creates a case-insensitive hash

=head1 SYNOPSIS

  use CGI qw/header/;
  use Blosxom::Header::Adapter;

  my %adaptee = ( -type => 'text/plain' );

  tie my %adapter => 'Blosxom::Header::Adapter' => \%adaptee;

  $adapter{Content_Length} = 1234;

  print header( %adaptee );
  # Content-length: 1234
  # Content-Type: text/plain; charset=ISO-8859-1
  #

=head1 DESCRIPTION

Creates a case-insensitive hash.

=head2 BACKGROUND

Blosxom, an weblog application, globalizes C<$header> which is a reference to
a hash. This application passes C<$header> to C<CGI::header()> to generate HTTP
headers.

  package blosxom;
  use strict;
  use warnings;
  use CGI qw/header/;

  our $header = { -type => 'text/html' };

  # Loads plugins

  print header( $header );

Plugins may modify C<$header> directly because the variable is global.
On the other hand, C<header()> doesn't care whether C<keys> of C<$header> are
lowercased nor start with a dash.
There is no agreement with how to normalize C<keys> of C<$header>.

=head2 HOW THIS MODULE NORMALIZES FIELD NAMES

To specify field names consistently, we need to normalize them.
If you follow one of normalization rules, you can modify C<$header>
consistently. This module normalizes them as follows.

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

=item $adapter = tie %adapter, 'Blosxom::Header::Adapter', \%adaptee

Associates a new hash instance with Blosxom::Header::Adapter.

=item $adapter{ $field } = $value

=item $value = $adapter{ $field }

=item $deleted = delete $adapter{ $field }

=item $bool = exists $adapter{ $field }

=item $bool = %adapter

=item $field = each %adapter

=item ( $field, $value ) = each %adapter

=item %adapter = ()

A shortcut for

  %adaptee = ( -type => q{} );

=item $adapter->nph()

=item $adapter->attachment()

=item $adapter->has_date_header()

=back

=head1 DIAGONOSTICS

=over 4

=item The Date header is fixed

You attempted to modify the Date header when any of
<-cookie>, C<-nph> or C<-expires> was set.
See C<Blosxom::Header::date()>.

=back

=head1 SEE ALSO

L<Blosxom::Header>,
L<perltie>

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
