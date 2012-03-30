use inc::Module::Install;

name 'Blosxom-Header';
all_from 'lib/Blosxom/Header.pm';

requires 'Carp';
requires 'Exporter';

test_requires 'Test::More';
test_requires 'Test::Warn';
test_requires 'Test::Base';
test_requires 'YAML';
test_requires 'Test::Pod';

tests_recursive;

WriteAll;
