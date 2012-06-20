package Blosxom::Header::Proxy;
use strict;
use warnings;
use Carp qw/croak/;
use List::Util qw/first/;

# Naming conventions
#   $field : raw field name (e.g. Foo-Bar)
#   $norm  : normalized field name (e.g. -foo_bar)

sub TIEHASH { bless \$blosxom::header, shift }

sub FETCH {
    my ( $self, $field ) = @_;
    my $norm = $self->norm_of( $field );
    return $self->content_type if $norm eq '-content_type';    
    return $self->content_disposition if $norm eq '-content_disposition';    
    $self->header->{ $norm };
}

sub STORE {
    my ( $self, $field, $value ) = @_;

    my $header = $self->header;
    my $norm = $self->norm_of( $field );

    if ( $norm eq '-content_type' ) {
        my $has_charset = $value =~ /\bcharset\b/;
        delete $header->{-charset} if $has_charset;
        $header->{-charset} = q{} unless $has_charset;
        $norm = '-type';
    }
    elsif ( $norm eq '-content_disposition' ) {
        delete $header->{-attachment};
    }
    elsif ( $norm eq '-attachment' ) {
        delete $header->{-content_disposition};
    }

    $header->{ $norm } = $value;

    return;
}

sub DELETE {
    my ( $self, $field ) = @_;
    
    my $header = $self->header;
    my $norm = $self->norm_of( $field );

    if ( $norm eq '-content_type' ) {
        my $deleted = $self->content_type( $header );
        delete $header->{-charset};
        $header->{-type} = q{};
        return $deleted;
    }
    elsif ( $norm eq '-content_disposition' ) {
        my $deleted = $self->content_disposition( $header );
        delete $header->{-attachment};
        return $deleted;
    }

    delete $header->{ $norm };
}

sub EXISTS {
    my ( $self, $field ) = @_;

    my $header = $self->header;
    my $norm = $self->norm_of( $field );

    if ( $norm eq '-content_type' ) {
        my $type = $header->{-type};
        return ( $type or !defined $type );
    }
    elsif ( $norm eq '-content_disposition' ) {
        return 1 if $header->{-attachment};
    }

    exists $header->{ $norm };
}

sub CLEAR { %{ shift->header } = ( -type => q{} ) }

sub FIRSTKEY {
    my $self = shift;
    keys %{ $self->header };
    $self->NEXTKEY;
}

sub NEXTKEY {
    my ( $self, $lastkey ) = @_;

    return if $lastkey and $lastkey eq 'Content-Type';

    my $norm;
    while ( my ( $key, $value ) = each %{ $self->header } ) {
        next unless $value;
        next if $key eq '-charset' or $key eq '-nph' or $key eq '-type';
        $norm = $key;
        last;
    }

    return 'Content-Type' if !$norm and $self->EXISTS( '-content_type' );

    $norm && $self->field_name_of( $norm );
}

sub SCALAR {
    my $self = shift;
    my %header = %{ $self->header }; # copy
    return 1 unless %header;
    my ( $type ) = delete @header{ '-type', '-charset' };
    return 1 if $type or !defined $type; # Content-Type exists
    my $scalar = first { $_ } values %header;
    $scalar ? 1 : 0;
}

sub header {
    my $self = shift;
    return $$self if $self->is_initialized;
    croak( q{$blosxom::header hasn't been initialized yet.} );
}

sub is_initialized { ref ${ $_[0] } eq 'HASH' }

{
    my %norm_of = (
        -cookies       => '-cookie',
        -set_cookie    => '-cookie',
        -window_target => '-target',
    );

    sub norm_of {
        my $self = shift;

        # lowercase a given string
        my $norm  = lc shift;

        # add an initial dash if not exists
        $norm = "-$norm" unless $norm =~ /^-/;

        # transliterate dashes into underscores in field names
        substr( $norm, 1 ) =~ tr{-}{_};

        $norm_of{ $norm } || $norm;
    }
}

{
    my %field_name_of = (
        -attachment => 'Content-Disposition',
        -cookie     => 'Set-Cookie',
        -target     => 'Window-Target',
        -p3p        => 'P3P',
    );

    sub field_name_of {
        my ( $self, $norm ) = @_;

        my $field = $field_name_of{ $norm };
        
        if ( !$field ) {
            # get rid of an initial dash if exists
            $norm =~ s/^-//;

            # transliterate underscores into dashes
            $norm =~ tr/_/-/;

            # uppercase the first character
            $field = ucfirst $norm;
        }

        $field;
    }
}

sub content_type {
    my $self   = shift;
    my $header = shift || $self->header;

    my ( $type, $charset ) = @{ $header }{ '-type', '-charset' };

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

    $charset ? "$type; charset=$charset" : $type;
}

sub content_disposition {
    my $self = shift;
    my $header = shift || $self->header;
    my $attachment = $header->{-attachment};
    return qq{attachment; filename="$attachment"} if $attachment;
    $header->{-content_disposition};
}

1;

__END__

=head1 NAME

Blosxom::Header::Proxy

=head1 SYNOPSIS

  use Blosxom::Header::Proxy;

  my $proxy = tie my %proxy => 'Blosxom::Header::Proxy';

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item $proxy = tie %proxy => 'Blosxom::Header::Proxy'

Associates a new hash instance with Blosxom::Header::Proxy.

=item %proxy = ()

A shortcut for

  %{ $blosxom::header } = ( -type => q{} );

=item $bool = %proxy

  $blosxom::header = { -type => q{} };
  $bool = %proxy; # false

  $blosxom::header = {};
  $bool = %proxy; # true

=item $bool = $proxy->is_initialized

A shortcut for

  $bool = ref $blosxom::header eq 'HASH';

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
