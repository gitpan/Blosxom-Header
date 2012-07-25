use strict;
use warnings;
use Benchmark qw/cmpthese/;

my %field_name_of = (
    -target => 'Window-Target', -p3p => 'P3P',
    -cookie => 'Set-Cookie', -type => 'Content-Type',
    -attachment => 'Content-Disposition',
);

my $denormalize = sub {
    my $norm = shift;
    unless ( exists $field_name_of{ $norm } ) {
        ( my $field = $norm ) =~ s/^-//;
        $field =~ tr/_/-/;
        $field_name_of{ $norm } = ucfirst $field;
    }
    $field_name_of{ $norm };
};

my $field_names = sub {
    my %header = @_;

    my @fields;

    push @fields, 'Content-Type' unless exists $header{-type};
    push @fields, 'Set-Cookie' if my $cookie  = delete $header{-cookie};
    push @fields, 'Expires'    if my $expires = delete $header{-expires};
    push @fields, 'Date' if delete $header{-nph} or $cookie or $expires;

    delete $header{-charset};
    while ( my ($norm, $value) = each %header ) {
        push @fields, $denormalize->( $norm ) if $value;
    }

    @fields;
};

my $field_names_sorted1 = sub {
    my %header = @_;

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
        push @fields, $denormalize->( $norm );
    }

    push @fields, 'Content-Type' if !exists $header{-type} or $header{-type};

    @fields;
};

my $field_names_sorted2 = sub {
    my %header = @_;

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
    #while ( my ($norm, $value) = each %header ) {
    #    next if !$value or $norm eq '-type';
    #    push @fields, $denormalize->( $norm );
    #}
    #my @others = grep { $header{$_} } keys %header;
    #push @fields, map { $denormalize->( $_ ) } @others;
    for my $norm ( keys %header ) {
        push @fields, $denormalize->( $norm ) if $header{$norm};
    }

    push @fields, 'Content-Type' if !exists $header{-type} or $header{-type};

    @fields;
};


my @headers = (
    -attachment => 1,
    -nph => 1,
    -status => 1,
    -target => 1,
    -p3p => 1,
    -cookie => 1,
    -expires => 1,
    -type => 1,
    -foo => 1,
    -foo_bar => 1,
);

cmpthese(50000, {
    field_names => sub { $field_names->( @headers ) },
    field_names_sorted1 => sub { $field_names_sorted1->( @headers ) },
    field_names_sorted2 => sub { $field_names_sorted2->( @headers ) },
});
