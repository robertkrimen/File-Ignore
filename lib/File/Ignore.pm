package File::Ignore;
# ABSTRACT: Ignore files that are good to ignore

use warnings;
use strict;

use File::Spec;

sub test {
    my $self = shift;
    my $test = shift;
    my $path = shift;

    my ( undef, $folder, $file ) = File::Spec->splitpath( $path );
    my @folder = File::Spec->splitdir( $folder );
    
}

1;

__END__

=head1 SYNOPSIS

    use File::Ignore;

    if (File::Ignore->ignore($file)) {
        # ... Skip ...
    }
    else {
        # Continue to process...
    }

    my $good = File::Ignore->include(qw(src/RCS apple.Z doc/apple.txt tags .svn banana.html core));
    for my $file (@$good) {
        # doc/apple.txt
        #  banana.html
    }

    my $bad = File::Ignore->exclude([qw(src/RCS apple.Z doc/apple.txt tags .svn banana.html core)]);
    for my $file (@$bad) {
        # src/RCS
        # apple.Z
        # tags
        # .svn
        # core
    }

=head1 USAGE

=head2 File::Ignore->ignore( <file> )

Returns true if <file> is one of the ignoreable.

=head2 File::Ignore->include( <file>, <file>, ... )

Returns an array reference of each <file> that is NOT ignoreable (should be included)

=head2 File::Ignore->exclude( <file>, <file>, ... )

Returns an array reference of each <file> that IS ignoreable (should be excluded)

=head2 File::Ignore->ignoreable

Returns a list of what is ignoreable. Currently, this is:

                 regexp        category           

    RCS/         RCS           rcs revision rsync 
    SCCS/        SCCS          revision rsync sccs
    CVS/         CVS           cvs revision rsync 
    CVS.adm      CVS\.adm      cvs revision rsync 
    RCSLOG       RCSLOG        rcs revision rsync 
    cvslog.*     cvslog\..*    cvs revision rsync 
    tags         tags          ctags etags rsync  
    TAGS         TAGS          ctags etags rsync  
    .make.state  \.make\.state make rsync         
    .nse_depinfo \.nse_depinfo rsync              
    *~           .*~           rsync              
    #*           #.*           rsync              
    .#*          \.#.*         rsync              
    ,*           ,.*           rsync              
    _$*          _\$.*         rsync              
    *$           .*\$          rsync              
    *.old        .*\.old       backup rsync       
    *.bak        .*\.bak       backup rsync       
    *.BAK        .*\.BAK       backup rsync       
    *.orig       .*\.orig      backup rsync       
    *.rej        .*\.rej       patch rsync        
    .del-*       \.del-.*      rsync              
    *.a          .*\.a         object rsync       
    *.olb        .*\.olb       object rsync       
    *.o          .*\.o         object rsync       
    *.obj        .*\.obj       object rsync       
    *.so         .*\.so        object rsync       
    .exe         \.exe         object rsync       
    *.Z          .*\.Z         rsync              
    *.elc        .*\.elc       rsync              
    *.ln         .*\.ln        rsync              
    core         core          core rsync         
    .svn/        \.svn         revision rsync svn
    .sw[p-z]     \.sw[p-z]     swap vim  

The above list was taken from C<rsync -C>

=cut

use File::Spec;

sub _make_entry {
    local $_ = shift;
    my $original = $_;
    my $tags = "";
    $tags = $1 if s/:(.*)$//;
    my $specification = $_;
    my @tags = split m/\s*,\s*/, $tags;
    my %tag = map { $_ => 1 } @tags;
    my $scope = "basename";
    $scope = "path" if m/^\//;
    my $prune = 0;
    $prune = 1 if s/\/$//;
    my ($prunere, $pruneqr);
    if ($prune) {
        $prunere = "(?:^|\\/)$_(?:$|\\/)";
        $pruneqr = qr/$prunere/;
    }
    
    $_ =~ s/\$/\\\$/g;
    $_ =~ s/\./\\./g;
    $_ =~ s/\*/\.\*/g;

    return { specification => $specification, original => $original, re => $_, qr => qr/$_/, scope => $scope, prune => $prune, prunere => $prunere, pruneqr => $pruneqr, tags => \@tags, tag => \%tag };
}

my @_ignore;
{
    no warnings qw/ qw /;
    push @_ignore, map { _make_entry $_ } (qw(
        RCS/:revision,rcs,rsync
        SCCS/:revision,sccs,rsync
        CVS/:revision,cvs,rsync
        CVS.adm:revision,cvs,rsync
        RCSLOG:revision,rcs,rsync
        cvslog.*:revision,cvs,rsync
        tags:etags,ctags,rsync
        TAGS:etags,ctags,rsync
        .make.state:make,rsync
        .nse_depinfo:rsync
        *~:rsync
        #*:rsync
        .#*:rsync
        ,*:rsync
        _$*:rsync
        *$:rsync
        *.old:backup,rsync
        *.bak:backup,rsync
        *.BAK:backup,rsync
        *.orig:backup,rsync
        *.rej:patch,rsync
        .del-*:rsync
        *.a:object,rsync
        *.olb:object,rsync
        *.o:object,rsync
        *.obj:object,rsync
        *.so:object,rsync
        .exe:object,rsync
        *.Z:rsync
        *.elc:rsync
        *.ln:rsync
        core:core,rsync
        .svn/:revision,svn,rsync
        .sw[p-z]:vim,swap
    ));
}

my @_path = grep { $_->{scope} eq "path" } @_ignore;
my @_basename = @_ignore;
my @_prune = grep { $_->{prune} } @_ignore;

sub ignore {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $self = __PACKAGE__;
    my $option = {};
    $option = shift if ref $_[0] eq "HASH";
    my $file = shift;

    return $self->_collect(1, $option, [ $file ]) ? 1 : 0; # Should we exclude this file? 
}

sub include {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $self = __PACKAGE__;
    my $option = {};
    $option = shift if ref $_[0] eq "HASH";
    my $each = ref $_[0] eq "ARRAY" ? $_[0] : [ @_ ];

    return $self->_collect(0, $option, $each) || [];
}

sub exclude {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $self = __PACKAGE__;
    my $option = {};
    $option = shift if ref $_[0] eq "HASH";
    my $each = ref $_[0] eq "ARRAY" ? $_[0] : [ @_ ];

    return $self->_collect(1, $option, $each) || [];
}

sub _collect {
    my $self = shift;
    my $collect_ignoreable = shift;
    my $option = {};
    $option = shift if ref $_[0] eq "HASH";
    my $each = shift;

    my @collection;
PATH:
    for my $path (@$each) {
        my $original_path = $path = "$path";
        $path =~ s/\/$//;
        my ($volume, $directory_path, $basename) = File::Spec->splitpath($path);

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
            if ($basename =~ $_->{qr}) {
                push @collection, $original_path if $collect_ignoreable;
                next PATH;
            }
        }

        for (@ign_path) {
            if ($path =~ $_->{qr}) {
                push @collection, $original_path if $collect_ignoreable;
                next PATH;
            }
        }

        if ($option->{pruneable}) {
            for (@ign_prune) {
                if ($path =~ $_->{pruneqr}) {
                    push @collection, $original_path if $collect_ignoreable;
                    next PATH;
                }
            }
        }

        push @collection, $original_path unless $collect_ignoreable;
    }

    return unless @collection;
    return \@collection;
}

sub ignoreable {
    return [ @_ignore ];
}

1;
