#!/usr/bin/perl
# 13_to.t
# Generate a new EyeDrops.pm as described in the doco:
# "EyeDropping EyeDrops.pm" section.
# Run various tests on the EyeDrop'ed EyeDrops.pm.
# Since this test is very slow only run if the
# PERL_SMOKE environment variable is set.

use strict;
use File::Basename ();
use File::Copy ();
use File::Path ();
use Acme::EyeDrops qw(sightly);
use Test::Harness ();

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub skip_test {
   my $msg = @_ ? shift() : '';
   print "1..0 # Skipped: $msg\n";
   exit;
}

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d; close(F);
}

sub get_first_line {
   my $f = shift; local *T; open(T, $f) or die "open '$f': $!";
   my $s = <T>; close(T); $s;
}

sub rm_f_file
{
   my $f = shift;
   -f $f or return;
   unlink($f) or die "error: unlink '$f':$!";
}

sub rm_f_dir
{
   my $d = shift;
   -d $d or return;
   File::Path::rmtree($d, 0, 0);
   -d $d and die "error: could not delete everything in '$d': $!";
}

# --------------------------------------------------

skip_test('Skipping long running generator tests unless $ENV{PERL_SMOKE} is true')
   unless $ENV{PERL_SMOKE};

print STDERR "Long running generated tests running...\n";
print STDERR "(these are only run if PERL_SMOKE environment variable is true).\n";

print "1..3\n";

# --------------------------------------------------

sub eye_drop_eyedrops_pm {
   # Slurp EyeDrops.pm into $orig string.
   my $orig = Acme::EyeDrops::slurp_yerself();
   # Split $orig into the source ($src) and the pod ($doc).
   my ($src, $doc) = split(/\n1;\n/, $orig, 2);
   # Remove the line containing $this_dir = __FILE__ ...
   # because this line confuses eval.
   $src =~ s/^(my \$this_dir\b.*)$//m;
   # Return the new sightly version of EyeDrops.pm.
   $1 . sightly( { Regex         => 0,
                   Compact       => 1,
                   TrapEvalDie   => 1,
                   InformHandler => sub {},
                   Shape         => 'camel',
                   Gap           => 1,
                   SourceString  => $src } )
   . ";\n1;\n" . $doc;
}

# Copy lib/Acme to temporary new $genbase.
sub create_eyedrops_tree {
   my ($fromdir, $todir) = @_;

   my $fromdrops = "$fromdir/lib/Acme/EyeDrops";
   my $todrops   = "$todir/lib/Acme/EyeDrops";
   File::Path::mkpath($todrops, 0, 0777) or
      die "error: mkpath '$todrops': $!";

   local *D;
   opendir(D, $fromdrops) or die "error: opendir '$fromdrops': $!";
   my @eye = grep(/\.eye$/, readdir(D));
   closedir(D);

   for my $f (@eye) {
      File::Copy::copy("$fromdrops/$f", "$todrops/$f")
         or die "error: File::Copy::copy '$f': $!";
   }
   build_file("$todir/lib/Acme/EyeDrops.pm", eye_drop_eyedrops_pm());
}

# --------------------------------------------------

my $genbase = 'knob';

my $base = File::Basename::dirname($0);
# In the normal case, $base will be set to 't'.
# If you are naughtily running the tests from the t directory,
# base will probably be set to '.'.
my $frombase = $base eq 't' ? '.' : '..';

rm_f_dir($genbase);
create_eyedrops_tree($frombase, $genbase);

# --------------------------------------------------

my $outf = 'out.tmp';
my $errf = 'err.tmp';
-f $outf and (unlink($outf) or die "error: unlink '$outf': $!");
-f $errf and (unlink($errf) or die "error: unlink '$errf': $!");

my $itest = 0;

# --------------------------------------------------

# Run unsightly tests with TestHarness::runtests.

my @unames = (
   '00_Coffee.t',
   '01_mug.t',
   '02_shatters.t',
   '03_Larry.t',
   '04_Apocalyptic.t',
   '05_Parrot.t',
   '06_not.t',
   '07_a.t',
   '08_hoax.t',
   '09_Gallop.t',
   '10_Ponie.t',
   '11_bold.t',
);

my @tests = map("$base/$_", @unames);

# --------------------------------------------------
# Run with normal EyeDrops.pm as a speed comparison.

local *SAVERR; open(SAVERR, ">&STDERR");  # save original STDERR
local *SAVOUT; open(SAVOUT, ">&STDOUT");  # save original STDOUT
open(STDOUT, '>'.$outf) or die "Could not create '$outf': $!";
open(STDERR, '>'.$errf) or die "Could not create '$errf': $!";

my $status = Test::Harness::runtests(@tests);

open(STDERR, ">&SAVERR");  # restore STDERR
open(STDOUT, ">&SAVOUT");  # restore STDOUT

my $outstr = Acme::EyeDrops::slurp_tfile($outf);
my $errstr = Acme::EyeDrops::slurp_tfile($errf);

print STDERR "stdout of TestHarness::runtests:\n$outstr\n";
print STDERR "stderr of TestHarness::runtests:\n$errstr\n";

$status or print "not ";
++$itest; print "ok $itest - TestHarness::runtests of unsightly EyeDrops.pm plain tests\n";

# --------------------------------------------------
# Now run with generated EyeDrops.pm.

local @INC = @INC;
unshift(@INC, "$genbase/lib");

local *SAVERR; open(SAVERR, ">&STDERR");  # save original STDERR
local *SAVOUT; open(SAVOUT, ">&STDOUT");  # save original STDOUT
open(STDOUT, '>'.$outf) or die "Could not create '$outf': $!";
open(STDERR, '>'.$errf) or die "Could not create '$errf': $!";

$status = Test::Harness::runtests(@tests);

open(STDERR, ">&SAVERR");  # restore STDERR
open(STDOUT, ">&SAVOUT");  # restore STDOUT

$outstr = Acme::EyeDrops::slurp_tfile($outf);
$errstr = Acme::EyeDrops::slurp_tfile($errf);

print STDERR "stdout of TestHarness::runtests:\n$outstr\n";
print STDERR "stderr of TestHarness::runtests:\n$errstr\n";

$status or print "not ";
++$itest; print "ok $itest - TestHarness::runtests of sightly EyeDrops.pm, plain tests\n";

# --------------------------------------------------

# Run sightly tests with TestHarness::runtests.

my %attrs = (
   Shape          => 'camel',
   Regex          => 0,
   Compact        => 1,
   TrapEvalDie    => 1,
   InformHandler  => sub {},
   Shape          => 'camel',
   Gap            => 1
);
my @pnames = @unames;
# zsightly.t test works but the following might be written to stderr:
# Scalar found where operator expected at (eval 2) line 41, near "regex_eval_sightly($hellostr"
# This seems to happen only on Perl versions before 5.6.1. Is this a Perl bug?

# --------------------------------------------------

# Generate sightly-encoded versions of test programs (see also gen.t and 12_Beer.t).

for my $p (@pnames) {
   $attrs{SourceFile} = "$base/$p";
   # Assume first line is #!/usr/bin/perl (needed for taint mode tests).
   my $s_new = get_first_line($attrs{SourceFile}) .
               "# This program was generated by yharn.t\n";
   $s_new .= sightly(\%attrs);
   build_file("$base/z$p", $s_new);
}

# Run them with TestHarness::runtests

@tests = map("$base/z$_", @pnames);

local *SAVERR; open(SAVERR, ">&STDERR");  # save original STDERR
local *SAVOUT; open(SAVOUT, ">&STDOUT");  # save original STDOUT
open(STDOUT, '>'.$outf) or die "Could not create '$outf': $!";
open(STDERR, '>'.$errf) or die "Could not create '$errf': $!";

$status = Test::Harness::runtests(@tests);

open(STDERR, ">&SAVERR");  # restore STDERR
open(STDOUT, ">&SAVOUT");  # restore STDOUT

$outstr = Acme::EyeDrops::slurp_tfile($outf);
$errstr = Acme::EyeDrops::slurp_tfile($errf);

print STDERR "stdout of TestHarness::runtests:\n$outstr\n";
print STDERR "stderr of TestHarness::runtests:\n$errstr\n";

$status or print "not ";
++$itest; print "ok $itest - TestHarness::runtests of sightly EyeDrops.pm, generated tests\n";

# ----------------------------------------------------

for my $t (@tests) { unlink($t) or die "error: unlink '$t': $!" }

rm_f_dir($genbase);

unlink($outf) or die "error: unlink '$outf': $!";
unlink($errf) or die "error: unlink '$errf': $!";

exit 0;
