use strict;
use Acme::EyeDrops qw(ascii_to_sightly sightly_to_ascii sightly);

print "1..11\n";

my $t1 = 'abcdefghijklmnopqrstuvwxyz';
my $f1 = ascii_to_sightly($t1);
$f1 =~ /[ A-Za-z0-9]/ and print "not ";
print "ok 1\n";

my $t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 2\n";

$t1 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
$f1 = ascii_to_sightly($t1);
$f1 =~ /[ A-Za-z0-9]/ and print "not ";
print "ok 3\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 4\n";

$t1 = '0123456789';
$f1 = ascii_to_sightly($t1);
$f1 =~ /[ A-Za-z0-9]/ and print "not ";
print "ok 5\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 6\n";

$t1 = "\n";
$f1 = ascii_to_sightly($t1);
$f1 =~ /[ A-Za-z0-9]/ and print "not ";
print "ok 7\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 8\n";

$t1 = join("", map {chr} 0..255);
$f1 = ascii_to_sightly($t1);
$f1 =~ /[ A-Za-z0-9]/ and print "not ";
print "ok 9\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 10\n";

# Test self-printing JAPH.
my $src = <<'PROG';
open 0;
$/ = undef;
$x = <0>;
close 0;
$x =~ tr/!-~/#/;
print $x;
PROG
my $prog = sightly({ Shape         => 'japh',
                     SourceString  => $src,
                     Regex         => 1 } );
open(TT, '>japh.tmp') or die "open >japh.tmp: $!";
print TT $prog;
close(TT);
my $outstr = `$^X japh.tmp`;
my $jfile = 'lib/Acme/japh.eye';
open(TT, $jfile) or die "open '$jfile': $!";
my $japhstr;
{
   local $/ = undef; $japhstr = <TT>;
}
close(TT);
$outstr eq $japhstr or print "not ";
print "ok 11\n";
