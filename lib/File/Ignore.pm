package File::Ignore;

use warnings;
use strict;

=head1 NAME

File::Ignore - Ignore files that are good to ignore

=head1 VERSION

Version 0.010_1

=cut

our $VERSION = '0.010_1';


=head1 SYNOPSIS

    use File::Ignore;

    if (File::Ignore->check($file)) {
        # ... Skip ...
    }
    else {
        # Continue to process...
    }

=head1 METHODS

=head2 match( <file> )

Returns true if <file> is one of:

    RCS  SCCS  CVS  CVS.adm RCSLOG cvslog.* tags TAGS .make.state .nse_depinfo *~ #* .#* ,* _$* *$ *.old *.bak *.BAK *.orig *.rej .del-* *.a *.olb *.o
    *.obj *.so *.exe *.Z *.elc *.ln core .svn/

This list taken from rsync -C 

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-ignore at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Ignore>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Ignore


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Ignore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Ignore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Ignore>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Ignore>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

sub _make_entry {
    local $_ = shift;
    my $original = $_;
    my $tags;
    $tags = $1 if s/:(.*)$//;
    my @tags = split m/\s*,\s*/, $tags;
    my %tag = map { $_ => 1 } @tags;
    my $scope = "basename";
    $scope = "path" if m/^\//;
    my $prune = 0;
    $prune = 1 if m/\/$/;
    my ($prunere, $pruneqr);
    if ($prune) {
        $prunere = "(?:^|\\/)$_";
        $pruneqr = qr/$prunere/;
    }
    
    $_ =~ s/./\\./g;
    $_ =~ s/\*/\.\*/g;

    return { original => $original, re => $_, qr => qr/$_/, scope => $scope, prune => $prune, prunere => $prunere, pruneqr => $pruneqr, tags => \@tags, tag => \%tag };
}

my @_ignore;
{
    no warnings qw/qw/;
    push @_ignore, map { _make_entry $_ } (qw(
        RCS:revision,rcs,rsync
        SCCS:revision,sccs,rsync
        CVS:revision,cvs,rsync
        CVS.adm:revision,cvs,rsync
        RCSLOG:revision,rcs,rsync
        cvslog.*:revision,cvs,rsync
        tags:etags,ctags,rsync
        TAGS:etags,ctags,rsync
        .make.state:make,rsync
        .nse_depinfo,rsync
        *~,rsync
        #*,rsync
        .#*,rsync
        ,*,rsync
        _$*,rsync
        #*$,rsync
        *.old:backup,rsync
        *.bak:backup,rsync
        *.BAK:backup,rsync
        *.orig:backup,rsync
        *.rej:patch,rsync
        .del-*,rsync
        *.a:object,rsync
        *.olb:object,rsync
        *.o:object,rsync
        *.obj:object,rsync
        *.so:object ,rsync
        .exe:object,rsync
        *.Z,rsync
        *.elc,rsync
        *.ln,rsync
        core:core,rsync
        .svn/:revision,svn,rsync
    ));
}

my @_path = grep { $_->{scope} eq "path" } @_ignore;
my @_basename = grep { $_->{scope} eq "basename" } @_ignore;
my @_prune = grep { $_->{prune} } @_ignore;

sub check {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $option = {};
    $option = shift if ref $_[0] eq "HASH";
    my $path = shift;

    $path = "$path";
    my ($volume, $directory_path, $basename) = splitpath $path;

    my (@ign_basename, @ign_path, @ign_prune);
    if (my $tag = $option->{tag}) {
        @ign_basename = map { $_->{tag}->{$tag} } @_basename;
        @ign_path = map { $_->{tag}->{$tag} } @_path;
        @ign_prune = map { $_->{tag}->{$tag} } @_prune;
    }
    else {
        @ign_basename = @_basename;
        @ign_path = @_path;
        @ign_prune = @_prune;
    }

    for (@ign_basename) {
        return 1 if $basename =~ $_->{qr};
    }

    for (@ign_path) {
        return 1 if $path =~ $_->{qr};
    }

    return 0 unless $option->{pruneable} || $option->{prune} || $option->{pruned};

    for (@ign_prune) {
        return 1 if $path =~ $_->{pruneqr};
    }

    return 0;
}

sub ignoreable {
    return [ @_ignore ];
}

1; # End of File::Ignore
