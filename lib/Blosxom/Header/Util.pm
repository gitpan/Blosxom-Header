package Blosxom::Header::Util;
use strict;
use warnings;
use Exporter 'import';
use HTTP::Date ();
use CGI::Util;

our @EXPORT_OK = qw( str2time time2str expires );

my %str2time;
sub str2time { $str2time{ $_[0] } ||= HTTP::Date::str2time( $_[0] ) }

my %time2str;
sub time2str { $time2str{ $_[0] } ||= HTTP::Date::time2str( $_[0] ) }

my %expires;
sub expires { $expires{ $_[0] } ||= CGI::Util::expires( $_[0] ) }

1;

__END__

=head1 NAME

Blosxom::Header::Util - Utility class for Blosxom::Header

=head1 SYNOPSIS

  use Blosxom::Header::Util qw/str2time time2str expires/;

  my $time = str2time( 'Sun, 06 Nov 1994 08:49:37 GMT' ); # 784111777
  my $date = time2str( 784111777 ); # Sun, 06 Nov 1994 08:49:37 GMT
  my $date = expires( '+3M' );

=head1 FUNCTIONS

The following functions are exported on demand.

=over 4

=item $time = str2time( $date )

A shortcut for

  $time = HTTP::Date::str2time( $date )

=item $date = time2str( $time )

A shortcut for

  $date = HTTP::Date::time2str( $time )

=item expires

=back

=head1 SEE ALSO

L<HTTP::Date>, L<CGI::Util>

=head1 MAINTAINER

Ryo Anazawa (anazawa@cpan.org)

=cut
