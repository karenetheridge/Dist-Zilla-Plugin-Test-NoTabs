package Dist::Zilla::Plugin::NoTabsTests;
# ABSTRACT: Release tests making sure hard tabs aren't used

use Moose;
use namespace::autoclean;

extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::More' => 0,
        'Test::NoTabs' => 0,
    );
}

=pod

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=for :list
* xt/release/no-tabs.t
a standard Test::NoTabs test

=cut

__PACKAGE__->meta->make_immutable;

1;

__DATA__
___[ xt/release/no-tabs.t ]___
use strict;
use warnings;
use Test::More;

use Test::NoTabs;

all_perl_files_ok();
