#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Ignore;

srand 42;

for ( grep { m/\S/ } split m/\n/, <<'_END_' ) {
RCS/
SCCS/
CVS/
CVS.adm
RCSLOG
cvslog.apple
tags
TAGS
.make.state
.nse_depinfo
apple~
#apple
.#apple
,apple
_$apple
apple$
apple.old
apple.bak
apple.BAK
apple.orig
apple.rej
.del-apple
apple.a
apple.olb
apple.o
apple.obj
apple.so
apple.exe
apple.Z
apple.elc
apple.ln
core
.svn/
apple.swp
apple.swr
apple.swz

RCS
SCCS
CVS
.svn

_END_
    ok( File::Ignore->ignore( $_ ), "Ignore $_" );
}

sub path {
    my $file = shift;
    my @path;
    push @path, "", if 1 == int rand 4;
    push @path, "apple", if 1 == int rand 4;
    push @path, "banana-", if 1 == int rand 4;
    push @path, "cherry", if 1 == int rand 4;
    push @path, ".grape", if 1 == int rand 4;
    return join "/", @path, $file;
}

for ( grep { m/\S/ } split m/\n/, <<'_END_' ) {
RCS/
SCCS/
CVS/
CVS.adm
RCSLOG
cvslog.apple
tags
TAGS
.make.state
.nse_depinfo
apple~
#apple
.#apple
,apple
_$apple
apple$
apple.old
apple.bak
apple.BAK
apple.orig
apple.rej
.del-apple
apple.a
apple.olb
apple.o
apple.obj
apple.so
apple.exe
apple.Z
apple.elc
apple.ln
core
.svn/
_END_
    my $path = path $_;
    ok( File::Ignore->ignore( $path ), "Ignore $path" );
}

for ( 0 .. 99 ) {
    my $path = path $_;
    ok( ! File::Ignore->ignore( $path ), "Do not ignore $path" );
}

cmp_deeply( File::Ignore->include(qw( src/RCS apple.Z doc/apple.txt tags .svn banana.html core )), [qw( doc/apple.txt banana.html )]);
cmp_deeply( File::Ignore->exclude(qw/ RCS apple.Z apple.txt tags .svn banana.html core /), [qw/ RCS apple.Z tags .svn core /]);

done_testing;
