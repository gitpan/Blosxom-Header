use strict;
use CGI;
use Test::More;

{
    my $q = CGI->new;
    my $header_ref = { type => 'text/plain' };
    like $q->header( $header_ref ), qr!^Content-Type: text/plain!;
}

{
    my $q = CGI->new;
    my $header_ref = { 'Content-Type' => 'text/plain' };
    like $q->header( $header_ref ), qr!^Content-Type: text/plain!;
}

{
    my $q = CGI->new;
    my $header_ref = { attachment => 'foo.png' };
    like $q->header( $header_ref ),
         qr!^Content-Disposition: attachment; filename=\"foo.png\"!;
}

{
    my $q = CGI->new;
    my $header_ref
        = { 'Content-Disposition' => 'attachment; filename="foo.png"' };
    like $q->header( $header_ref ),
         qr!^Content-disposition: attachment; filename=\"foo.png\"!;
}

{
    my $q = CGI->new;
    my $header_ref = { charset => 'utf-8' };
    like $q->header( $header_ref ),
         qr!^Content-Type: text/html; charset=utf-8!;
}

{
    my $q = CGI->new;
    my $header_ref = { cookie => 'foo' };
    like $q->header( $header_ref ), qr{^Set-Cookie: foo};
}

{
    my $q = CGI->new;
    my $header_ref = { cookie => [ 'foo', 'bar' ]  };
    like $q->header( $header_ref ),
         qr!^Set-Cookie: foo${CGI::CRLF}Set-Cookie: bar!;
}

{
    my $q = CGI->new;
    my $header_ref = { nph => 1 };
    like $q->header( $header_ref ),
         qr!^HTTP/1.0 200 OK${CGI::CRLF}Server: cmdline!;
}

{
    my $q = CGI->new;
    my $header_ref = { p3p => [qw(CAO DSP LAW CURa)] };
    like $q->header( $header_ref ),
         qr!^P3P: policyref="/w3c/p3p.xml", CP="CAO DSP LAW CURa"!;
}

done_testing;
