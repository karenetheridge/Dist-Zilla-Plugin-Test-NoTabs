use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ ExecDir => ],
                [ 'FileFinder::ByName' => ExtraTestFiles => { dir => 'xt' } ],
                [ 'Test::NoTabs' => { finder => [ ':InstallModules', ':TestFiles' ], file => [ 'examples/foo' ] } ],
            ),
            path(qw(source lib Foo.pm)) => <<'MODULE',
package Foo;
use strict;
use warnings;
1;
MODULE
            path(qw(source lib Bar.pod)) => <<'POD',
package Bar;
=pod

=cut
POD
            path(qw(source bin myscript)) => <<'SCRIPT',
use strict;
use warnings;
print "hello there!\n";
SCRIPT
            path(qw(source t foo.t)) => <<'TEST',
use strict;
use warnings;
use Test::More tests => 1;
pass('hi!');
TEST
            path(qw(source examples foo)) => <<'EXAMPLE',
use strict;
use warnings;
print "hello there!\n";
EXAMPLE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt author no-tabs.t));
ok( -e $file, 'test created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');
unlike($content, qr/\t/m, 'no tabs in generated test');

my @files = (
    path(qw(lib Foo.pm)),
    path(qw(lib Bar.pod)),
    path(qw(t foo.t)),
    path(qw(examples foo)),
);
like($content, qr/'\Q$_\E'/m, "test checks $_") foreach @files;

unlike($content, qr/'\Q$_\E'/m, "test does not check $_") foreach (
    path(qw(bin myscript)),
    path(qw(xt bar.t)),
);

# not needed, but Test::NoTabs loads it from the generated test, and $0 is wrong for it
# (FIXME in Test::NoTabs!!)
use FindBin;

my $files_tested;

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;

    $files_tested = Test::Builder->new->current_test;
};

is($files_tested, @files, 'correct number of files were tested');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
