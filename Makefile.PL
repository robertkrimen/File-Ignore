use inc::Module::Install;

name 'File-Ignore';
all_from 'lib/File/Ignore.pm';

build_requires 'Test::More';

auto_install;

WriteAll;

