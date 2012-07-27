package Blosxom::Header::Adapter;
use strict;
use warnings;
use Blosxom::Header::Util;
use Carp qw/carp/;
use CGI::Util;
use List::Util qw/first/;

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

    my %field_name_of = (
        -attachment => 'Content-Disposition', -cookie => 'Set-Cookie',
        -type       => 'Content-Type',        -target => 'Window-Target',
        -p3p        => 'P3P',
    );

    $self->{denormalize} = sub {
        my $norm = shift;
        unless ( exists $field_name_of{ $norm } ) {
            ( my $field = $norm ) =~ s/^-//;
            $field =~ tr/_/-/;
            return $field_name_of{ $norm } = ucfirst $field;
        }
        $field_name_of{ $norm };
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
    elsif ( $norm eq '-date' and $self->date_header_is_fixed ) {
        return Blosxom::Header::Util::expires( time );
    }
    elsif ( $norm eq '-p3p' ) {
        my $p3p = $adaptee->{ $norm };
        return unless $p3p;
        my $tags = ref $p3p eq 'ARRAY' ? join ' ', @$p3p : $p3p;
        return qq{policyref="/w3c/p3p.xml" CP="$tags"};
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
    elsif ( $norm eq '-date' and $self->date_header_is_fixed ) {
        return carp( 'The Date header is fixed' );
    }
    elsif ( $norm eq '-p3p' ) {
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
    elsif ( $norm eq '-date' and $self->date_header_is_fixed ) {
        return carp( 'The Date header is fixed' );
    }
    elsif ( $norm eq 'p3p' ) {
        delete $adaptee->{-p3p};
        return $self->FETCH( 'P3P' );
    }

    delete $adaptee->{ $norm };
}

sub CLEAR {
    my $self = shift;
    %{ $self->{adaptee} } = ( -type => q{} );
}

sub SCALAR {
    my $self = shift;
    my $header = $self->{adaptee};
    return 1 unless exists $header->{-type}; 
    first { $_ } values %{ $header };
}

sub field_names {
    my $self   = shift;
    my %header = %{ $self->{adaptee} };

    my @fields;

    push @fields, 'Status'        if delete $header{-status};
    push @fields, 'Window-Target' if delete $header{-target};
    push @fields, 'P3P'           if delete $header{-p3p};

    push @fields, 'Set-Cookie' if my $cookie  = delete $header{-cookie};
    push @fields, 'Expires'    if my $expires = delete $header{-expires};
    push @fields, 'Date' if delete $header{-nph} or $cookie or $expires;

    push @fields, 'Content-Disposition' if delete $header{-attachment};

    # not ordered
    delete $header{-charset};
    while ( my ($norm, $value) = each %header ) {
        next if !$value or $norm eq '-type';
        push @fields, $self->{denormalize}->( $norm );
    }

    push @fields, 'Content-Type' if !exists $header{-type} or $header{-type};

    @fields;
}

sub denormalize { shift->{denormalize}->( @_ ) }

sub normalize {
    my $self  = shift;
    my $field = lc shift;

    # transliterate dashes into underscores
    $field =~ tr{-}{_};

    # add an initial dash
    $field = "-$field";

    return $self->{norm_of}{$field} if exists $self->{norm_of}{$field};

    $field;
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

sub date_header_is_fixed {
    my $adaptee = shift->{adaptee};
    $adaptee->{-expires} || $adaptee->{-cookie} || $adaptee->{-nph};
}

sub p3p_tags {
    my $self    = shift;
    my $adaptee = $self->{adaptee};

    if ( @_ ) {
        my @tags = @_ > 1 ? @_ : split / /, shift;
        $adaptee->{-p3p} = @tags > 1 ? \@tags : $tags[0];
    }
    elsif ( my $tags = $adaptee->{-p3p} ) {
        my @tags = ref $tags eq 'ARRAY' ? @{ $tags } : ( $tags );
        @tags = map { split / / } @tags;
        return wantarray ? @tags : $tags[0];
    }

    return;
}

sub push_p3p_tags {
    my ( $self, @values ) = @_;
    my $adaptee = $self->{adaptee};

    if ( my $value = $adaptee->{-p3p} ) {
        return push @{ $value }, @values if ref $value eq 'ARRAY';
        unshift @values, $value;
    }

    $adaptee->{-p3p} = @values > 1 ? \@values : $values[0];

    scalar @values;
}

sub expires {
    my $self = shift;
    my $expires = $self->{adaptee}->{-expires};
    return unless $expires;
    Blosxom::Header::Util::expires( $expires );
}

1;

__END__

=head1 NAME

Blosxom::Header::Adapter - Adapter for CGI::header()

=head1 SYNOPSIS

  use Blosxom::Header::Adapter;

  my %adaptee = ( -type => 'text/plain' );

  tie my %adapter => 'Blosxom::Header::Adapter' => \%adaptee;

  # field names are case-insensitive
  my $length = $adapter{'Content-Length'}; # 1234
  $adapter{'content_length'} = 4321;

  print header( %adaptee );
  # Content-length: 4321
  # Content-Type: text/plain; charset=ISO-8859-1
  #

=head1 DESCRIPTION

Adapter for L<CGI>::header().

=head2 METHODS

=over 4

=item $adapter = tie %adapter, 'Blosxom::Header::Adapter', \%adaptee

=item $value = $adapter{ $field }

=item $adapter{ $field } = $value

=item $deleted = delete $adapter{ $field }

=item $bool = scalar %adapter

=item %adapter = ()

A shortcut for

  %adaptee = ( -type => q{} );

=item $bool = exists %adapter{ $field }

=item $norm = $adapter->normalize( $field )

=item $adapter->nph

=item $adapter->attachment

=item $bool = $adapter->date_header_is_fixed

=item @tags = $adapter->p3p_tags

=item $adapter->p3p_tags( @tags )

=item $adapter->push_p3p_tags( @tags )

=item $date = $adapter->expires

=back

=head1 DIAGONOSTICS

=over 4

=item The Date header is fixed

You attempted to modify the Date header when any of
C<-cookie>, C<-nph> or C<-expires> was set.

=back

=head1 SEE ALSO

L<Tie::Hash>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
