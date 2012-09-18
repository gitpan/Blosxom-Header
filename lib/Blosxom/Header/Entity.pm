package Blosxom::Header::Entity;
use strict;
use warnings;
use overload '%{}' => 'as_hashref', 'fallback' => 1;
use parent 'Blosxom::Header::Adapter';
use Carp qw/carp croak/;
use Scalar::Util qw/refaddr/;

my %adapter_of;

sub new {
    my $class = shift;
    my $adaptee = ref $_[0] eq 'HASH' ? shift : {};
    my $self = tie my %adapter => $class => $adaptee;
    $adapter_of{ refaddr $self } = \%adapter;
    $self;
}

sub as_hashref { $adapter_of{ refaddr shift } }

sub get {
    my ( $self, @fields ) = @_;
    my @values = map { $self->FETCH($_) } @fields;
    wantarray ? @values : $values[-1];
}

sub set {
    my ( $self, @headers ) = @_;

    if ( @headers % 2 == 0 ) {
        while ( my ($field, $value) = splice @headers, 0, 2 ) {
            $self->STORE( $field => $value );
        }
    }
    else {
        croak 'Odd number of elements passed to set()';
    }

    return;
}

sub delete {
    my ( $self, @fields ) = @_;

    if ( wantarray ) {
        return map { $self->DELETE($_) } @fields;
    }
    elsif ( defined wantarray ) {
        my $deleted = @fields && $self->DELETE( pop @fields );
        $self->DELETE( $_ ) for @fields;
        return $deleted;
    }
    else {
        $self->DELETE( $_ ) for @fields;
    }

    return;
}

sub clear    { shift->CLEAR        }
sub exists   { shift->EXISTS( @_ ) }
sub is_empty { not shift->SCALAR   }

sub flatten {
    my $self = shift;
    map { $_, $self->FETCH($_) } $self->field_names;
}

sub each {
    my ( $self, $callback ) = @_;

    if ( ref $callback eq 'CODE' ) {
        for my $field ( $self->field_names ) {
            $callback->( $field, $self->FETCH($field) );
        }
    }
    else {
        croak 'Must provide a code reference to each()';
    }

    return;
}

sub charset {
    my $self = shift;

    require HTTP::Headers::Util;

    my %param = do {
        my $type = $self->FETCH( 'Content-Type' );
        my ( $params ) = HTTP::Headers::Util::split_header_words( $type );
        return unless $params;
        splice @{ $params }, 0, 2;
        @{ $params };
    };

    if ( my $charset = $param{charset} ) {
        $charset =~ s/^\s+//;
        $charset =~ s/\s+$//;
        return uc $charset;
    }

    return;
}

sub content_type {
    my $self = shift;

    if ( @_ ) {
        my $content_type = shift;
        $self->STORE( 'Content-Type' => $content_type );
        return;
    }

    my ( $media_type, $rest ) = do {
        my $content_type = $self->FETCH( 'Content-Type' );
        return q{} unless defined $content_type;
        split /;\s*/, $content_type, 2;
    };

    $media_type =~ s/\s+//g;
    $media_type = lc $media_type;

    wantarray ? ($media_type, $rest) : $media_type;
}

BEGIN { *type = \&content_type }

sub date          { shift->_date_header( 'Date',          @_ ) }
sub last_modified { shift->_date_header( 'Last-Modified', @_ ) }

sub _date_header {
    my ( $self, $field, $time ) = @_;

    require HTTP::Date;

    if ( defined $time ) {
        $self->STORE( $field => HTTP::Date::time2str($time) );
    }
    elsif ( my $date = $self->FETCH($field) ) {
        return HTTP::Date::str2time( $date );
    }

    return;
}

sub set_cookie {
    my ( $self, $name, $value ) = @_;

    require CGI::Cookie;

    my $new_cookie = CGI::Cookie->new(do {
        my %args = ref $value eq 'HASH' ? %{ $value } : ( value => $value );
        $args{name} = $name;
        \%args;
    });

    my @cookies;
    if ( my $cookies = $self->FETCH('Set-Cookie') ) {
        @cookies = ref $cookies eq 'ARRAY' ? @{ $cookies } : $cookies;
        for my $cookie ( @cookies ) {
            next unless ref $cookie eq 'CGI::Cookie';
            next unless $cookie->name eq $name;
            $cookie = $new_cookie;
            undef $new_cookie;
            last;
        }
    }

    push @cookies, $new_cookie if $new_cookie;

    $self->STORE( 'Set-Cookie' => @cookies > 1 ? \@cookies : $cookies[0] );

    return;
}

sub get_cookie {
    my $self   = shift;
    my $name   = shift;
    my $cookie = $self->FETCH( 'Set-Cookie' );

    my @values = grep {
        ref $_ eq 'CGI::Cookie' and $_->name eq $name
    } (
        ref $cookie eq 'ARRAY' ? @{ $cookie } : $cookie,
    );

    wantarray ? @values : $values[0];
}

sub status {
    my $self = shift;

    require HTTP::Status;

    if ( @_ ) {
        my $code = shift;
        my $message = HTTP::Status::status_message( $code );
        return $self->STORE( Status => "$code $message" ) if $message;
        carp "Unknown status code '$code' passed to status()";
    }
    elsif ( my $status = $self->FETCH('Status') ) {
        return substr( $status, 0, 3 );
    }
    #else {
    #    return 200;
    #}

    return;
}

sub target {
    my $self = shift;
    return $self->STORE( 'Window-Target' => shift ) if @_;
    $self->FETCH( 'Window-Target' );
}

sub dump {
    my $self = shift;

    require Data::Dumper;

    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 1;

    my %self = (
        adaptee => $self->header,
        adapter => { $self->flatten },
    );

    Data::Dumper::Dumper( \%self );
}

sub UNTIE {
    my $self = shift;
    delete $adapter_of{ refaddr $self };
    return;
}

sub DESTROY {
    my $self = shift;
    $self->UNTIE;
    $self->SUPER::DESTROY;
}

1;
