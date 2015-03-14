package Dist::Zilla::Plugin::Test::NoTabs;
# ABSTRACT: Author tests that ensure hard tabs are not used
# KEYWORDS: plugin test testing author development whitespace tab tabstop indent formatting
# vim: set ts=8 sts=4 sw=4 tw=78 et :

use Moose;
use Path::Tiny;
use Sub::Exporter::ForMethods 'method_installer'; # method_installer returns a sub.
use Data::Section 0.004 # fixed header_re
    { installer => method_installer }, '-setup';
use Moose::Util::TypeConstraints 'role_type';
use namespace::autoclean;

with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => {
        method          => 'found_files',
        finder_arg_names => [ 'finder' ],
        default_finders => [ ':InstallModules', ':ExecFiles', ':TestFiles' ],
    },
    'Dist::Zilla::Role::PrereqSource';

has filename => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub { return 'xt/author/no-tabs.t' },
);

has files => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { files => 'elements' },
    lazy => 1,
    default => sub { [] },
);

has _file_obj => (
    is => 'rw', isa => role_type('Dist::Zilla::Role::File'),
);

sub mvp_multivalue_args { qw(files module_finder script_finder) }
sub mvp_aliases { return { file => 'files' } }

around BUILDARGS => sub
{
    my $orig = shift;
    my $self = shift;
    my $args = $self->$orig(@_);

    # handle legacy args
    my $module_finder = delete $args->{module_finder};
    my $script_finder = delete $args->{script_finder};
    if ($module_finder or $script_finder)
    {
        $args->{zilla}->log('folding deprecated options (module_finder, script_finder) into finder');
        $args->{finder} = [ $args->finder ] if $args->{finder} and not ref $args->{finder};

        push @{$args->{finder}},
            $module_finder
                ? (ref $module_finder ? @$module_finder : $module_finder)
                : ':InstallModules';

        push @{$args->{finder}},
            $script_finder
            ? (ref $script_finder ? @$script_finder : $script_finder)
            : (':ExecFiles', ':TestFiles');
    }

    return $args;
};

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
         finder => $self->finder,
         filename => $self->filename,
    };
    return $config;
};

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::More' => '0.88',
        'Test::NoTabs' => '0',
    );
}

sub gather_files
{
    my $self = shift;

    require Dist::Zilla::File::InMemory;

    $self->add_file(
        $self->_file_obj(
            Dist::Zilla::File::InMemory->new(
                name => $self->filename,
                content => ${$self->section_data('__TEST__')},
            )
        )
    );
    return;
}

sub munge_files
{
    my $self = shift;

    my @filenames = map { path($_->name)->relative('.')->stringify }
        grep { not ($_->can('is_bytes') and $_->is_bytes) }
        @{ $self->found_files };
    push @filenames, $self->files;

    $self->log_debug('adding file ' . $_) foreach @filenames;

    my $file = $self->_file_obj;
    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist => \($self->zilla),
                plugin => \$self,
                filenames => \@filenames,
            }
        )
    );

    return;
}

__PACKAGE__->meta->make_immutable;

=pod

=for Pod::Coverage::TrustPod
    mvp_aliases
    register_prereqs
    gather_files
    munge_files

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::NoTabs]
    finder = my_finder
    finder = other_finder

=head1 DESCRIPTION

This is a plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
providing the file F<xt/author/no-tabs.t>, a standard L<Test::NoTabs> test.

=head1 CONFIGURATION OPTIONS

This plugin accepts the following options:

=head2 C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
files to check.  The default value is C<:InstallModules>,
C<:ExecFiles> (see also L<Dist::Zilla::Plugin::ExecDir>) and C<:TestFiles>;
this option can be used more than once.

Other predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> plugin.

=head2 C<file>

a filename to also test, in addition to any files found
earlier. This option can be repeated to specify multiple additional files.

=head2 C<filename>

The filename of the test to add - defaults to F<xt/author/no-tabs.t>.

=head1 SEE ALSO

=for :list
* Test::NoTabs
* Test::Tabs

=cut

__DATA__
___[ __TEST__ ]___
use strict;
use warnings;

# this test was generated with {{ ref($plugin) . ' ' . ($plugin->VERSION || '<self>') }}

use Test::More 0.88;
use Test::NoTabs;

my @files = (
{{ join(",\n", map { "    '" . $_ . "'" } map { s/'/\\'/g; $_ } sort @filenames) }}
);

notabs_ok($_) foreach @files;
done_testing;
