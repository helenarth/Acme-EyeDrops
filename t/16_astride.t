#!/usr/bin/perl
# 16_astride.t - simple threads test.

use strict;
use Config;
use Acme::EyeDrops qw(ascii_to_sightly sightly_to_ascii);

sub skip_test { print "1..0 # Skipped: $_[0]\n"; exit }

BEGIN {
   $] >= 5.008 && $Config{'useithreads'} or skip_test('no threads');
   eval { require threads };
   skip_test('threads module required for testing threads') if $@;
   'threads'->import();

   eval { require Test::More };
   skip_test('Test::More required for testing threads') if $@;
   Test::More->import();
}

# --------------------------------------------------

$|=1;

my $Num_Threads =  3;
my $N_Iter      = 10;

plan tests => $Num_Threads * ($N_Iter * 2) + $Num_Threads;

sub do_one_thread {
   my $kid = shift;
   print "# kid $kid start\n";
   for my $j (1 .. $N_Iter) {
      my $t1 = join("", map(chr, 0..255));
      my $f1 = ascii_to_sightly($t1);
      unlike( $f1, qr/[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/, 'ascii_to_sightly' );
      my $t1a = sightly_to_ascii($f1);
      is( $t1, $t1a, 'sightly_to_ascii' );
   }
   print "# kid $kid exit\n";
   return 42;
}

my @kids = ();
for my $i (1 .. $Num_Threads) {
   my $t = threads->new(\&do_one_thread, $i);
   print "# parent $$: continue\n";
   push(@kids, $t);
}
for my $t (@kids) {
   print "# parent $$: waiting for join\n";
   my $rc = $t->join();
   cmp_ok( $rc, '==', 42, "threads exit status is $rc" );
}
