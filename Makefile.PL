use inc::Module::Install;

name 'Blosxom-Header';
all_from 'lib/Blosxom/Header.pm';

requires 'HTTP::Status';
test_requires 'Test::More';
test_requires 'Test::Warn';

WriteAll;

