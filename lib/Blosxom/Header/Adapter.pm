package Blosxom::Header::Adapter;
use strict;
use warnings;
use Blosxom::Header::Util;
use Carp qw/carp/;
use List::Util qw/first/;

sub TIEHASH {
    my ( $class, $adaptee ) = @_;

    my %norm_of = (
        -attachment => q{},        -charset       => q{},
        -cookie     => q{},        -nph           => q{},
        -set_cookie => q{-cookie}, -target        => q{},
        -type       => q{},        -window_target => q{-target},
    );

    my %field_name_of = (
        -attachment => 'Content-Disposition', -cookie => 'Set-Cookie',
        -p3p        => 'P3P',                 -target => 'Window-Target',
        -type       => 'Content-Type',
    );

    my $denormalize = sub {
        my $norm = shift;
        unless ( exists $field_name_of{ $norm } ) {
            ( my $field = $norm ) =~ s/^-//;
            $field =~ tr/_/-/;
            return $field_name_of{ $norm } = ucfirst $field;
        }
        $field_name_of{ $norm };
    };

    my %self = (
        adaptee     => $adaptee,
        norm_of     => \%norm_of,
        denormalize => $denormalize,
    );

    bless \%self, $class;
}

sub FETCH {
    my $self   = shift;
    my $norm   = $self->normalize( shift );
    my $header = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        my $type    = $header->{-type};
        my $charset = $header->{-charset};

        if ( defined $type and $type eq q{} ) {
            undef $charset;
            undef $type;
        }
        elsif ( !defined $type ) {
            $type = 'text/html';
        }

        if ( $type ) {
            if ( $type =~ /\bcharset\b/ ) {
                undef $charset;
            }
            elsif ( !defined $charset ) {
                $charset = 'ISO-8859-1';
            }
        }

        return $charset ? "$type; charset=$charset" : $type;
    }
    elsif ( $norm eq '-content_disposition' ) {
        if ( my $attachment = $header->{-attachment} ) {
            return qq{attachment; filename="$attachment"};
        }
    }
    elsif ( $norm eq '-date' ) {
        if ( $self->date_header_is_fixed ) {
            return Blosxom::Header::Util::expires( time );
        }
    }
    elsif ( $norm eq '-p3p' ) {
        if ( my $p3p = $header->{-p3p} ) {
            my $tags = ref $p3p eq 'ARRAY' ? join ' ', @{ $p3p } : $p3p;
            return qq{policyref="/w3c/p3p.xml" CP="$tags"};
        }
        else {
            return;
        }
    }

    $header->{ $norm };
}

sub EXISTS {
    my $self   = shift;
    my $norm   = $self->normalize( shift );
    my $header = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        return 1 unless exists $header->{-type};
        return !defined $header->{-type} || $header->{-type};
    }
    elsif ( $norm eq '-content_disposition' ) {
        return 1 if $header->{-attachment};
    }
    elsif ( $norm eq '-date' ) {
        return 1 if $self->date_header_is_fixed;
    }

    $header->{ $norm };
}

sub STORE {
    my $self   = shift;
    my $norm   = $self->normalize( shift );
    my $value  = shift;
    my $header = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        if ( $value =~ /\bcharset\b/ ) {
            delete $header->{-charset};
        }
        else {
            $header->{-charset} = q{};
        }
        $header->{-type} = $value;
        return;
    }
    elsif ( $norm eq '-content_disposition' ) {
        delete $header->{-attachment};
    }
    elsif ( $norm eq '-date' ) {
        if ( $self->date_header_is_fixed ) {
            return carp( 'The Date header is fixed' );
        }
    }
    elsif ( $norm eq '-p3p' ) {
        return;
    }
    elsif ( $norm eq '-expires' or $norm eq '-cookie' ) {
        delete $header->{-date};
    }

    $header->{ $norm } = $value;

    return;
}

sub DELETE {
    my $self   = shift;
    my $field  = shift;
    my $norm   = $self->normalize( $field );
    my $header = $self->{adaptee};

    if ( $norm eq '-content_type' ) {
        my $deleted = $self->FETCH( $field );
        delete $header->{-charset};
        $header->{-type} = q{};
        return $deleted;
    }
    elsif ( $norm eq '-content_disposition' ) {
        my $deleted = $self->FETCH( $field );
        delete @{ $header }{ $norm, '-attachment' };
        return $deleted;
    }
    elsif ( $norm eq '-date' ) {
        if ( $self->date_header_is_fixed ) {
            return carp( 'The Date header is fixed' );
        }
    }
    elsif ( $norm eq '-p3p' ) {
        my $deleted = $self->FETCH( $field );
        delete $header->{-p3p};
        return $deleted;
    }

    delete $header->{ $norm };
}

sub CLEAR {
    my $self = shift;
    %{ $self->{adaptee} } = ( -type => q{} );
}

sub SCALAR {
    my $self = shift;
    return 1 if $self->EXISTS( 'Content-Type' ); 
    first { $_ } values %{ $self->{adaptee} };
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
    delete @header{qw/-charset -type/};
    while ( my ($norm, $value) = each %header ) {
        push @fields, $self->{denormalize}->( $norm ) if $value;
    }

    push @fields, 'Content-Type' if $self->EXISTS( 'Content-Type' );

    @fields;
}

sub denormalize {
    my ( $self, $norm ) = @_;
    $self->{denormalize}->( $norm );
}

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
    my $self   = shift;
    my $header = $self->{adaptee};
    
    if ( @_ ) {
        my $nph = shift;
        delete $header->{-date} if $nph;
        $header->{-nph} = $nph;
    }
    else {
        return $header->{-nph};
    }

    return;
}

sub date_header_is_fixed {
    my $self = shift;
    my $header = $self->{adaptee};
    $header->{-expires} || $header->{-cookie} || $header->{-nph};
}

sub p3p_tags {
    my $self   = shift;
    my $header = $self->{adaptee};

    if ( @_ ) {
        my @tags = @_ > 1 ? @_ : split / /, shift;
        $header->{-p3p} = @tags > 1 ? \@tags : $tags[0];
    }
    elsif ( my $tags = $header->{-p3p} ) {
        my @tags = ref $tags eq 'ARRAY' ? @{ $tags } : ( $tags );
        @tags = map { split / / } @tags;
        return wantarray ? @tags : $tags[0];
    }

    return;
}

sub push_p3p_tags {
    my ( $self, @tags ) = @_;
    my $header = $self->{adaptee};

    if ( my $tags = $header->{-p3p} ) {
        return push @{ $tags }, @tags if ref $tags eq 'ARRAY';
        unshift @tags, $tags;
    }

    $header->{-p3p} = @tags > 1 ? \@tags : $tags[0];

    scalar @tags;
}

sub expires {
    my $self   = shift;
    my $header = $self->{adaptee};

    if ( my $expires = $header->{-expires} ) {
        return Blosxom::Header::Util::expires( $expires );
    }

    return;
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
