use strict;
use warnings;
use Benchmark qw/cmpthese/;
use Blosxom::Header;

{
    package blosxom;

    our $header = {
        -type       => 'text/plain',
        -charset    => 'utf-8',
        -attachment => 'genome.jpg',
        -p3p        => [qw/CAO DSP LAW CURa/],
        -target     => 'ResultsWindow',
        -foo        => 'bar',
        -bar        => 'baz',
        -expires    => '+3M',
        -nph        => 1,
        -status     => '304 Not Modified',
    };
}

my $header = Blosxom::Header->instance;
$header->last_modified( time );

cmpthese(100000, {
    'Content-Type'        => sub { my $v = $header->{Content_Type}        },
    'Content-Disposition' => sub { my $v = $header->{Content_Disposition} },
    'P3P'                 => sub { my $v = $header->{P3P}                 },
    'Window-Target'       => sub { my $v = $header->{Window_Target}       },
    'Foo'                 => sub { my $v = $header->{Foo}                 },
    'Bar'                 => sub { my $v = $header->{Bar}                 },
    'Date'                => sub { my $v = $header->{Date}                },
    'Expires'             => sub { my $v = $header->{Expires}             },
});

cmpthese(300000, {
    'charset'             => sub { my $v = $header->charset       },
    'date'                => sub { my $v = $header->date          },
    'expires'             => sub { my $v = $header->expires       },
    'attachment'          => sub { my $v = $header->attachment    },
    'content_type'        => sub { my $v = $header->content_type  },
    'content_type (LIST)' => sub { my @v = $header->content_type  },
    'nph'                 => sub { my $v = $header->nph           },
    'p3p_tags'            => sub { my @v = $header->p3p_tags      },
    'status'              => sub { my $v = $header->status        },
    'target'              => sub { my $v = $header->target        },
    'last_modified'       => sub { my $v = $header->last_modified },
});
