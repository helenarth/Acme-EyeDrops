#!/usr/bin/perl
# 13_to.t
# Tests get_eye_dir()

use strict;
use Acme::EyeDrops qw(get_eye_dir);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

print "1..3\n";

my $itest = 0;

# -----------------------------------------------------------------------
# get_eye_dir tests

my $eyedir = get_eye_dir();
$eyedir or print "not ";
++$itest; print "ok $itest - get_eye_dir sane\n";
-d $eyedir or print "not ";
++$itest; print "ok $itest - get_eye_dir dir\n";
-f "$eyedir/camel.eye" or print "not ";
++$itest; print "ok $itest - get_eye_dir camel.eye\n";

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

exit 0;
