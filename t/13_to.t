#!/usr/bin/perl
# 13_to.t
# Tests get_eye_dir(), slurp_yerself()
# get_eye_properties(), get_eye_keywords(), find_eye_shapes()

use strict;
use Acme::EyeDrops qw(get_eye_dir
                      get_eye_shapes
                      get_eye_properties
                      get_eye_keywords
                      find_eye_shapes);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

my $tmpf = 'bill.tmp';

# --------------------------------------------------
# A valid property file should:
#  1) contain no "weird" chars.
#  2) no line should contain trailing spaces
#  3) be properly newline-terminated
#  4) contain no leading newlines
#  5) contain no trailing newlines
# test_one_propchars() below verifies that is
# the case for all .eyp shapes.
#  6) contain only valid properties
# Tested by get_prop_names()
#  7) contain only valid keywords
# Tested near the end via get_eye_keywords().
# --------------------------------------------------

my @eye_shapes = get_eye_shapes();
my $n_tests = @eye_shapes * 6;
$n_tests += 71;   # plus property tests

print "1..$n_tests\n";

# --------------------------------------------------

my $itest = 0;

# -----------------------------------------------------------------------

sub test_one_propchars {
   my ($e, $s) = @_;
   $s =~ tr K-_:$@*&!%.;"'`()[]{},/\\ a-zA-Z0-9\nKKc and print "not ";
   ++$itest; print "ok $itest - $e valid chars\n";
   $s =~ / +$/m and print "not ";
   ++$itest; print "ok $itest - $e trailing spaces\n";
   substr($s, 0, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e leading blank lines\n";
   substr($s, -1, 1) eq "\n" or print "not ";
   ++$itest; print "ok $itest - $e trailing blank lines\n";
   substr($s, -2, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e properly newline terminated\n";
}

sub get_prop_names {
   my %h;
   for my $s (get_eye_shapes()) {
      my $p = get_eye_properties($s) or next;  # no properties
      my @k = keys(%{$p}) or next;
      for my $k (@k) { push(@{$h{$k}}, $s) }
   }
   return \%h;
}

# Hacked from _get_eye_shapes().
sub _get_eyp_shapes {
   my $d = shift; local *D;
   opendir(D, $d) or die "opendir '$d': $!";
   my @e = sort map(/(.+)\.eyp$/, readdir(D)); closedir(D); @e;
}

# -----------------------------------------------------------------------
# slurp_yerself() tests (primitive)

my $eyedrops_pm = Acme::EyeDrops::slurp_yerself();
my $elen = length($eyedrops_pm);
$elen > 50000 or print "not ";
++$itest; print "ok $itest - slurp_yerself length is $elen\n";
my $nlines = $eyedrops_pm =~ tr/\n//;
$nlines > 1000 or print "not ";
++$itest; print "ok $itest - slurp_yerself line count is $nlines\n";

# XXX: could add MD5 checksum test here.
# XXX: beware above test is fragile when testing auto-generated EyeDrops.pm
#      (as is done by 19_surrounds.t)

# -----------------------------------------------------------------------
# get_eye_dir() tests.

my $eyedir = get_eye_dir();
$eyedir or print "not ";
++$itest; print "ok $itest - get_eye_dir sane\n";
-d $eyedir or print "not ";
++$itest; print "ok $itest - get_eye_dir dir\n";
-f "$eyedir/camel.eye" or print "not ";
++$itest; print "ok $itest - get_eye_dir camel.eye\n";
# v1.50 added eye property (.eyp) files.
-f "$eyedir/camel.eyp" or print "not ";
++$itest; print "ok $itest - get_eye_dir camel.eyp\n";

# -----------------------------------------------------------------------
# Sanity check on all properties files.

{
   # Check that .eye files and .eyp files match.
   my @eyp_shapes = _get_eyp_shapes($eyedir);
   # print STDERR "# There are: " . scalar(@eyp_shapes) . " property files\n";
   scalar(@eye_shapes) == scalar(@eyp_shapes) or print "not ";
   ++$itest; print "ok $itest - num .eyp matches num .eye\n";
   for my $i (0 .. $#eye_shapes) {
      $eye_shapes[$i] eq $eyp_shapes[$i] or print "not ";
      ++$itest; print "ok $itest - '$eye_shapes[$i]' .eye matches .eyp\n";
   }
}

for my $e (@eye_shapes) {
   test_one_propchars($e,
      Acme::EyeDrops::_slurp_tfile($eyedir . '/' . $e . '.eyp'));
}

{
   # XXX: need to update test when update shape properties.
   my $h = get_prop_names();
   # for my $k (sort keys %{$h}) { print "k='$k' v='@{$h->{$k}}'\n" }
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - valid props, hash ref\n";
   my @skey = sort keys %{$h};
   print STDERR "# properties: @skey\n";
   @skey == 3 or print "not ";
   ++$itest; print "ok $itest - valid props, number\n";
   for my $k ('description',
              'keywords',
              'nick') {
      shift(@skey) eq $k or print "not ";
      ++$itest; print "ok $itest - valid props, '$k'\n";
   }
}

# -----------------------------------------------------------------------
# _get_properties() tests.

{
   build_file($tmpf, "");
   my $h = Acme::EyeDrops::_get_properties($tmpf);
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - _get_properties, empty file 1\n";
   keys(%$h) == 0 or print "not ";
   ++$itest; print "ok $itest - _get_properties, empty file 2\n";
}

{
   build_file($tmpf, "tang:autrijus\n");
   my $h = Acme::EyeDrops::_get_properties($tmpf);
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - _get_properties, simple file 1\n";
   keys(%$h) == 1 or print "not ";
   ++$itest; print "ok $itest - _get_properties, simple file 2\n";
   $h->{'tang'} eq 'autrijus' or print "not ";
   ++$itest; print "ok $itest - _get_properties, simple file 3\n";
}

{
   build_file($tmpf, "  # comment\n \ttang \t :\t autrijus");
   my $h = Acme::EyeDrops::_get_properties($tmpf);
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - _get_properties, not term file 1\n";
   keys(%$h) == 1 or print "not ";
   ++$itest; print "ok $itest - _get_properties, not term file 2\n";
   $h->{'tang'} eq 'autrijus' or print "not ";
   ++$itest; print "ok $itest - _get_properties, not term file 3\n";
}

{
   build_file($tmpf, "wall:larry  \\\n \t not wall russ\n");
   my $h = Acme::EyeDrops::_get_properties($tmpf);
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - _get_properties, extendo file 1\n";
   keys(%$h) == 1 or print "not ";
   ++$itest; print "ok $itest - _get_properties, extendo file 2\n";
   $h->{'wall'} eq 'larry  not wall russ' or print "not ";
   ++$itest; print "ok $itest - _get_properties, extendo file 3\n";
}

{
   build_file($tmpf, " wall:larry\\\nnot wall russ\n\tConway: The  Damian \t\n");
   my $h = Acme::EyeDrops::_get_properties($tmpf);
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - _get_properties, two keys file 1\n";
   keys(%$h) == 2 or print "not ";
   ++$itest; print "ok $itest - _get_properties, two keys file 2\n";
   $h->{'wall'} eq 'larrynot wall russ' or print "not ";
   ++$itest; print "ok $itest - _get_properties, two keys file 3\n";
   $h->{'Conway'} eq 'The  Damian' or print "not ";
   ++$itest; print "ok $itest - _get_properties, two keys file 4\n";
}

# -----------------------------------------------------------------------
# get_eye_properties() tests.

{
   my $tmpprop = 'tmpeye.eyp';
   -f $tmpprop and (unlink($tmpprop) or die "error unlink '$tmpprop': $!");
   my $h = Acme::EyeDrops::_get_eye_properties('.', 'tmpeye');
   defined($h) and print "not ";
   ++$itest; print "ok $itest - get_eye_properties, no props\n";
}

{
   # XXX: need to update test when update shape properties.
   my $h = get_eye_properties('camel');
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - get_eye_properties, camel 1\n";
   keys(%$h) == 2 or print "not ";
   ++$itest; print "ok $itest - get_eye_properties, camel 2\n";
   $h->{'keywords'} eq 'animal' or print "not ";
   ++$itest; print "ok $itest - get_eye_properties, camel 3\n";
}

# -----------------------------------------------------------------------
# find_eye_shapes() tests.

eval { find_eye_shapes() };
$@ or print "not ";
++$itest; print "ok $itest - find_eye_shapes, no params\n";

{
   # XXX: need to update test when update shape properties.
   my @flags = find_eye_shapes('flag');
   @flags == 1 or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, one 1\n";
   $flags[0] eq 'flag_canada' or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, one 2\n";
}

{
   # XXX: need to update test when update shape properties.
   my @flags = find_eye_shapes('flag', 'flag');
   @flags == 1 or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, dup keyword 1\n";
   $flags[0] eq 'flag_canada' or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, dup keyword 2\n";
}

{
   # XXX: need to update test when update shape properties.
   # This is the example from the doco that cog specifically asked for.
   my @phackers = find_eye_shapes('face', 'person', 'perlhacker');
   @phackers == 12 or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, doco start\n";
   for my $hacker ('acme',
                   'autrijus',
                   'damian',
                   'dan',
                   'eugene',
                   'gelly',
                   'larry',
                   'larry2',
                   'merlyn',
                   'schwern2',
                   'simon',
                   'yanick') {
      shift(@phackers) eq $hacker or print "not ";
      ++$itest; print "ok $itest - find_eye_shapes, doco '$hacker'\n";
   }
   @phackers == 0 or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, doco end\n";
}

{
   # XXX: need to update test when update shape properties.
   my @flag_or_sport = find_eye_shapes('flag OR sport');
   @flag_or_sport == 3 or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, OR start\n";
   for my $fs ('cricket',
               'flag_canada',
               'golfer') {
      shift(@flag_or_sport) eq $fs or print "not ";
      ++$itest; print "ok $itest - find_eye_shapes, OR '$fs'\n";
   }
   @flag_or_sport == 0 or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes, OR end\n";
}

{
   # XXX: need to update test when update shape properties.
   my $h = get_eye_keywords();
   # for my $k (sort keys %{$h}) { print "k='$k' v='@{$h->{$k}}'\n" }
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - get_eye_keywords, hash ref\n";
   my @skey = sort keys %{$h};
   @skey == 12 or print "not ";
   ++$itest; print "ok $itest - get_eye_keywords, number\n";
   for my $k ('animal',
              'face',
              'flag',
              'hbanner',
              'map',
              'object',
              'perlhacker',
              'person',
              'planet',
              'sport',
              'underwear',
              'vbanner') {
      shift(@skey) eq $k or print "not ";
      ++$itest; print "ok $itest - get_eye_keywords, '$k'\n";
   }
}

# -----------------------------------------------------------------------
# Old tests -- function set_eye_dir() has been removed.

# my $mypwd =  Cwd::cwd();
# my $mytesteyedir  =  "$mypwd/eyedir.tmp";
# my $mytesteyefile =  "$mytesteyedir/tmp.eye";
# -d $mytesteyedir or (mkdir($mytesteyedir, 0777) or die "error: mkdir '$mytesteyedir': $!");
# build_file($mytesteyefile, $mytestshapestr);

# set_eye_dir($mytesteyedir);
# get_eye_dir() eq $mytesteyedir or print "not ";
# ++$itest; print "ok $itest - set_eye_dir sane\n";
# my @eyes = get_eye_shapes();
# @eyes==1 or print "not ";
# ++$itest; print "ok $itest - set_eye_dir number\n";
# $eyes[0] eq 'tmp' or print "not ";
# ++$itest; print "ok $itest - set_eye_dir filename\n";
# test_one_shape('tmp', get_eye_string('tmp'));

# This is just a simple example of testing die inside EyeDrops.pm.
# eval { set_eye_dir($mytesteyefile) };
# $@ or print "not ";
# ++$itest; print "ok $itest - set_eye_dir eval die\n";
# $@ eq "error set_eye_dir '" . $mytesteyefile . "': no such directory\n"
#    or print "not ";
# ++$itest; print "ok $itest - set_eye_dir eval die string\n";

# -----------------------------------------------------------------------

# unlink($mytesteyefile) or die "error: unlink '$mytesteyefile': $!";
# rmdir($mytesteyedir) or die "error: rmdir '$mytesteyedir': $!";

# --------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";

# ----------------------------------------------------------------
# Test for file that does not exist.

eval { Acme::EyeDrops::_get_properties($tmpf) };
$@ =~ /'\Q$tmpf\E':/ or print "not ";
++$itest; print "ok $itest - _get_properties, file not found\n";

eval { Acme::EyeDrops::_get_eye_shapes($tmpf) };
$@ =~ /'\Q$tmpf\E':/ or print "not ";
++$itest; print "ok $itest - _get_eye_shapes, dir not found\n";

# ----------------------------------------------------------------
