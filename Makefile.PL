use inc::Module::Install;

all_from 'lib/Blosxom/Header.pm';

repository 'https://github.com/anazawa/p5-Blosxom-Header';

requires 'overload'     => '1.06';
requires 'Carp'         => '1.10';
requires 'CGI::Util'    => '3.53';
requires 'CGI::Cookie'  => '1.29';
requires 'Exporter'     => '5.63';
requires 'HTTP::Date'   => '6.02';
requires 'HTTP::Status' => '6.03';
requires 'List::Util'   => '1.19';
requires 'Scalar::Util' => '1.19';

test_requires 'Test::Base'      => '0.60';
test_requires 'Test::Exception' => '0.31';
test_requires 'Test::More'      => '0.98';
test_requires 'Test::Pod'       => '1.45';
test_requires 'Test::Warn'      => '0.24';
test_requires 'CGI'             => '3.49';

tests 't/*.t t/*/*.t xt/*.t';

WriteAll;
