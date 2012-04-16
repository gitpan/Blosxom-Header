use inc::Module::Install;
all_from 'lib/Blosxom/Header.pm';
repository 'https://github.com/anazawa/p5-Blosxom-Header';

requires 'Carp';
test_requires 'Test::More';
test_requires 'Test::Base';
test_requires 'YAML';
test_requires 'Test::Pod';

WriteAll;
