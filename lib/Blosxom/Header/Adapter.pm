package Blosxom::Header::Adapter;
use strict;
use warnings;
use Carp qw/carp/;
use List::Util qw/first/;
use Scalar::Util qw/refaddr/;

my %adaptee_of;

sub TIEHASH {
    my ( $class, $adaptee ) = @_;
    my $self = bless \do { my $anon_scalar }, $class;
    $adaptee_of{ refaddr $self } = $adaptee;
    $self;
}

sub FETCH {
    my $self   = shift;
    my $norm   = $self->_normalize( shift );
    my $header = $adaptee_of{ refaddr $self };

    if ( $norm eq '-content_type' ) {
        my $type    = $header->{-type};
        my $charset = $header->{-charset};

        if ( defined $type and $type eq q{} ) {
            undef $charset;
            undef $type;
        }
        else {
            $type ||= 'text/html';

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
        if ( my $filename = $header->{-attachment} ) {
            return qq{attachment; filename="$filename"};
        }
    }
    elsif ( $norm eq '-date' ) {
        if ( $self->_date_header_is_fixed ) {
            require HTTP::Date;
            return HTTP::Date::time2str( time );
        }
    }
    elsif ( $norm eq '-expires' ) {
        if ( my $expires = $header->{-expires} ) {
            require CGI::Util;
            return CGI::Util::expires( $expires );
        }
    }
    elsif ( $norm eq '-p3p' ) {
        if ( my $p3p = $header->{-p3p} ) {
            my $tags = ref $p3p eq 'ARRAY' ? join ' ', @{ $p3p } : $p3p;
            return qq{policyref="/w3c/p3p.xml", CP="$tags"};
        }
    }

    $header->{ $norm };
}

sub STORE {
    my $self   = shift;
    my $norm   = $self->_normalize( shift );
    my $value  = shift;
    my $header = $adaptee_of{ refaddr $self };

    if ( $norm eq '-date' ) {
        if ( $self->_date_header_is_fixed ) {
            return carp 'The Date header is fixed';
        }
    }
    elsif ( $norm eq '-content_type' ) {
        $header->{-charset} = q{};
        $header->{-type} = $value;
        return;
    }
    elsif ( $norm eq '-content_disposition' ) {
        delete $header->{-attachment};
    }
    elsif ( $norm eq '-cookie' ) {
        delete $header->{-date};
    }
    elsif ( $norm eq '-p3p' or $norm eq '-expires' ) {
        carp "Can't assign to '$norm' directly, use accessors instead";
        return;
    }

    $header->{ $norm } = $value;

    return;
}

sub DELETE {
    my $self    = shift;
    my $field   = shift;
    my $norm    = $self->_normalize( $field );
    my $deleted = defined wantarray && $self->FETCH( $field );
    my $header  = $adaptee_of{ refaddr $self };

    if ( $norm eq '-date' ) {
        if ( $self->_date_header_is_fixed ) {
            return carp 'The Date header is fixed';
        }
    }
    elsif ( $norm eq '-content_type' ) {
        delete $header->{-charset};
        $header->{-type} = q{};
    }
    elsif ( $norm eq '-content_disposition' ) {
        delete $header->{-attachment};
    }

    delete $header->{ $norm };

    $deleted;
}

sub CLEAR {
    my $self = shift;
    my $header = $adaptee_of{ refaddr $self };
    %{ $header } = ( -type => q{} );
    return;
}

sub EXISTS {
    my $self   = shift;
    my $norm   = $self->_normalize( shift );
    my $header = $adaptee_of{ refaddr $self };

    if ( $norm eq '-content_type' ) {
        return !defined $header->{-type} || $header->{-type} ne q{};
    }
    elsif ( $norm eq '-content_disposition' ) {
        return 1 if $header->{-attachment};
    }
    elsif ( $norm eq '-date' ) {
        return 1 if first { $header->{$_} } qw(-nph -expires -cookie);
    }

    $header->{ $norm };
}

sub SCALAR {
    my $self = shift;
    my $header = $adaptee_of{ refaddr $self };
    !defined $header->{-type} || first { $_ } values %{ $header };
}

sub DESTROY {
    my $self = shift;
    delete $adaptee_of{ refaddr $self };
    return;
}

sub header { $adaptee_of{ refaddr shift } }

sub field_names {
    my $self   = shift;
    my $header = $adaptee_of{ refaddr $self };
    my %header = %{ $header }; # copy

    my @fields;

    push @fields, 'Status'        if delete $header{-status};
    push @fields, 'Window-Target' if delete $header{-target};
    push @fields, 'P3P'           if delete $header{-p3p};

    push @fields, 'Set-Cookie' if my $cookie  = delete $header{-cookie};
    push @fields, 'Expires'    if my $expires = delete $header{-expires};
    push @fields, 'Date' if delete $header{-nph} or $cookie or $expires;

    push @fields, 'Content-Disposition' if delete $header{-attachment};

    # not ordered
    my $type = delete @header{qw/-charset -type/};
    while ( my ($norm, $value) = each %header ) {
        push @fields, $self->_denormalize( $norm ) if $value;
    }

    push @fields, 'Content-Type' if !defined $type or $type ne q{};

    @fields;
}

sub attachment {
    my $self   = shift;
    my $header = $adaptee_of{ refaddr $self };

    if ( @_ ) {
        my $filename = shift;
        delete $header->{-content_disposition};
        $header->{-attachment} = $filename;
    }
    else {
        return $header->{-attachment};
    }

    return;
}

sub expires {
    my $self   = shift;
    my $header = $adaptee_of{ refaddr $self };

    if ( @_ ) {
        my $expires = shift;

        # CGI::header() automatically adds the Date header
        delete $header->{-date};

        $header->{-expires} = $expires;
    }
    elsif ( my $expires = $self->FETCH('Expires') ) {
        require HTTP::Date;
        return HTTP::Date::str2time( $expires );
    }

    return;
}

sub nph {
    my $self   = shift;
    my $header = $adaptee_of{ refaddr $self };
    
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

sub p3p_tags {
    my $self   = shift;
    my $header = $adaptee_of{ refaddr $self };

    if ( my @tags = @_ ) {
        $header->{-p3p} = @tags > 1 ? \@tags : $tags[0];
    }
    elsif ( my $tags = $header->{-p3p} ) {
        my @tags = ref $tags eq 'ARRAY' ? @{ $tags } : split ' ', $tags;
        return wantarray ? @tags : $tags[0];
    }

    return;
}

# this method is obsolete and will be removed in 0.07
sub push_p3p_tags {
    my $self   = shift;
    my @tags   = @_;
    my $header = $adaptee_of{ refaddr $self };

    unless ( @tags ) {
        carp 'Useless use of push_p3p_tags() with no values';
        return;
    }

    if ( my $tags = $header->{-p3p} ) {
        return push @{ $tags }, @tags if ref $tags eq 'ARRAY';
        unshift @tags, $tags;
    }

    $header->{-p3p} = @tags > 1 ? \@tags : $tags[0];

    scalar @tags;
}

sub _date_header_is_fixed {
    my $self = shift;
    my $header = $adaptee_of{ refaddr $self };
    $header->{-expires} || $header->{-cookie} || $header->{-nph};
}

my %norm_of = (
    -attachment => q{},        -charset       => q{},
    -cookie     => q{},        -nph           => q{},
    -set_cookie => q{-cookie}, -target        => q{},
    -type       => q{},        -window_target => q{-target},
);

sub _normalize {
    my $class = shift;
    my $field = lc shift;

    # transliterate dashes into underscores
    $field =~ tr{-}{_};

    # add an initial dash
    $field = "-$field";

    exists $norm_of{$field} ? $norm_of{ $field } : $field;
}

my %field_name_of = (
    -attachment => 'Content-Disposition', -cookie => 'Set-Cookie',
    -p3p        => 'P3P',                 -target => 'Window-Target',
    -type       => 'Content-Type',
);

sub _denormalize {
    my ( $class, $norm ) = @_;

    unless ( exists $field_name_of{$norm} ) {
        ( my $field = $norm ) =~ s/^-//;
        $field =~ tr/_/-/;
        $field_name_of{ $norm } = ucfirst $field;
    }

    $field_name_of{ $norm };
}

1;
