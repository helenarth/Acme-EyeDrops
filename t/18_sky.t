#!/usr/bin/perl
# 18_sky.t
# Test pod.
# I don't do any filtering, so no need to check blib also.
# This tests OK as taint-safe (i.e. with -Tw added to first line above)
# with recent versions of Perl, but not with Perl 5.005, which complains
# it cannot locate Acme/EyeDrops.pm in @INC.

use strict;
use File::Basename ();

sub skip_test { print "1..0 # Skipped: $_[0]\n"; exit }

BEGIN {
   eval { require Test::More };
   skip_test('Test::More required for testing POD') if $@;
   Test::More->import();
}

# --------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

eval { require Test::Pod };
skip_test('Test::Pod v0.95 required for testing POD')
   if $@ || $Test::Pod::VERSION < '0.95';
Test::Pod->import();

my $base = File::Basename::dirname($0);
# In the normal case, $base will be set to 't'.
# If you are naughtily running the tests from the t directory,
# base will probably be set to '.'.
my $fbase = $base eq 't' ? '.' : '..';
my @pod_files = ( "$fbase/lib/Acme/EyeDrops.pm" );

# ----------------------------------------------------

plan tests => scalar(@pod_files);
for my $f (@pod_files) { pod_file_ok($f) }

# ----------------------------------------------------

exit 0;
