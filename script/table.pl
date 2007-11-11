#!/usr/bin/perl -w

use strict;
use warnings;

use File::Ignore;
use Text::Table;

my @table = map { [
    $_->{specification},
    $_->{re},
    join " ", sort @{ $_->{tags} }
    ] } @{ File::Ignore->ignoreable };

my $table = Text::Table->new('', 'regexp', 'category');
$table->load(@table);
print $table;

