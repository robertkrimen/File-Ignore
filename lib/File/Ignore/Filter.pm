package File::Ignore::Filter;

use strict;
use warnings;

use Any::Moose;

has _ignore_list => qw/ is ro isa ArrayRef lazy_build 1 /;
sub _build__ignore_list { [] }

has _keep_list => qw/ is ro isa ArrayRef lazy_build 1 /;
sub _build__keep_list { [] }

sub ignore {
    my $self = shift;
    push @{ $self->_ignore_list }, @_;
}

sub keep {
    my $self = shift;
    push @{ $self->_keep_list }, @_;
}

sub block {
    my $self = shift;
}

sub pass {
    my $self = shift;
}




1;
