#!/usr/bin/perl
# 12_Beer.t (was banner test in vshape.t)
# This test is not taint-safe (rest of vshape.t is, so separate this one)

use strict;
use Acme::EyeDrops qw(make_banner);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub skip_test { print "1..0 # Skipped: $_[0]\n"; exit }

# make_banner is linux only (also requires /usr/games/banner executable)
my $have_banner = $^O eq 'linux' && -x '/usr/games/banner';

skip_test('Linux /usr/games/banner not available') unless $have_banner;

print "1..6\n";

my $itest = 0;

sub test_one_shape {
   my ($e, $s) = @_;
   $s =~ tr/ #\n//c and print "not ";
   ++$itest; print "ok $itest - $e valid chars\n";
   $s =~ /^#/m or print "not ";
   ++$itest; print "ok $itest - $e left justified\n";
   $s =~ / +$/m and print "not ";
   ++$itest; print "ok $itest - $e trailing spaces\n";
   substr($s, 0, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e leading blank lines\n";
   substr($s, -1, 1) eq "\n" or print "not ";
   ++$itest; print "ok $itest - $e trailing blank lines\n";
   substr($s, -2, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e properly newline terminated\n";
}

test_one_shape('make_banner', make_banner(70, "a bc"));

# -----------------------------------------------------------------------

exit 0;
