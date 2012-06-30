use inc::Module::Install;

all_from 'lib/Blosxom/Header.pm';

repository 'https://github.com/anazawa/p5-Blosxom-Header';

requires 'constant'     => '1.17';
requires 'Carp'         => '1.10';
requires 'Exporter'     => '5.63';
requires 'HTTP::Status' => '6.03';

test_requires 'Test::Base'      => '0.60';
test_requires 'Test::Exception' => '0.31';
test_requires 'Test::More'      => '0.98';
test_requires 'Test::Pod'       => '1.45';
test_requires 'Test::Warn'      => '0.24';

WriteAll;
