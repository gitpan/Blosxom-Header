use inc::Module::Install;

all_from 'lib/Blosxom/Header.pm';

repository 'https://github.com/anazawa/p5-Blosxom-Header';

requires Carp     => '1.10';
requires constant => '1.17';
requires 'HTTP::Status';

test_requires 'Test::Base';
test_requires 'Test::More' => '0.98';
test_requires 'Test::Pod';
test_requires 'Test::Warn';

WriteAll;
