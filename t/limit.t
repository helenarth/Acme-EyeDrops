use strict;
use Acme::EyeDrops qw(sightly regex_eval_sightly);

print "1..45\n";

my $tmpf = 'bill.tmp';

# Exact fit is 215 characters.
my $exact = 215;

my $srcstr = qq#print "abc\\n";\n#;
my $sightlystr = regex_eval_sightly($srcstr);
length($sightlystr) == $exact or print "not ";
print "ok 1\n";

# Exact fit abc ------------------------------------

my $prog = sightly({ Width         => $exact,
                     SourceString  => $srcstr,
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 2\n";
$outstr eq "abc\n" or print "not ";
print "ok 3\n";
my $nlf = $prog =~ tr/\n//;
$nlf == 1 or print "not ";
print "ok 4\n";
my $last = chop($prog);
$last eq "\n" or print "not ";
print "ok 5\n";
length($prog) == $exact or print "not ";
print "ok 6\n";
$prog eq $sightlystr or print "not ";
print "ok 7\n";
$last = chop($prog);
$last eq ')' or print "not ";
print "ok 8\n";

# One more  abc ------------------------------------

$prog = sightly({ Width         => $exact+1,
                  SourceString  => $srcstr,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 9\n";
$outstr eq "abc\n" or print "not ";
print "ok 10\n";
$nlf = $prog =~ tr/\n//;
$nlf == 1 or print "not ";
print "ok 11\n";
$last = chop($prog);
$last eq "\n" or print "not ";
print "ok 12\n";
length($prog) == $exact+1 or print "not ";
print "ok 13\n";
$last = chop($prog);
$last eq ';' or print "not ";
print "ok 14\n";
$prog eq $sightlystr or print "not ";
print "ok 15\n";

# One less  abc ------------------------------------

$prog = sightly({ Width         => $exact-1,
                  SourceString  => $srcstr,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 16\n";
$outstr eq "abc\n" or print "not ";
print "ok 17\n";
$nlf = $prog =~ tr/\n//;
$nlf == 2 or print "not ";
print "ok 18\n";
$last = chop($prog);
$last eq "\n" or print "not ";
print "ok 19\n";
my @lines = split(/\n/, $prog);
scalar(@lines) == 2 or print "not ";
print "ok 20\n";
my $fchar = substr($lines[1], 0, 1);
$fchar eq ')' or print "not ";
print "ok 21\n";
length($prog) == 2*($exact-1)+1 or print "not ";
print "ok 22\n";
my $nprog = $lines[0] . $fchar;
$nprog eq $sightlystr or print "not ";
print "ok 23\n";

# --------------------------------------------------
# Test with FillerVar = '#'

# Exact fit abc ------------------------------------

$prog = sightly({ Width         => $exact,
                  SourceString  => $srcstr,
                  FillerVar     => '#',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 24\n";
$outstr eq "abc\n" or print "not ";
print "ok 25\n";
$nlf = $prog =~ tr/\n//;
$nlf == 1 or print "not ";
print "ok 26\n";
$last = chop($prog);
$last eq "\n" or print "not ";
print "ok 27\n";
length($prog) == $exact or print "not ";
print "ok 28\n";
$prog eq $sightlystr or print "not ";
print "ok 29\n";
$last = chop($prog);
$last eq ')' or print "not ";
print "ok 30\n";

# One more  abc ------------------------------------

$prog = sightly({ Width         => $exact+1,
                  SourceString  => $srcstr,
                  FillerVar     => '#',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 31\n";
$outstr eq "abc\n" or print "not ";
print "ok 32\n";
$nlf = $prog =~ tr/\n//;
$nlf == 1 or print "not ";
print "ok 33\n";
$last = chop($prog);
$last eq "\n" or print "not ";
print "ok 34\n";
length($prog) == $exact+1 or print "not ";
print "ok 35\n";
$last = chop($prog);
$last eq ';' or print "not ";
print "ok 36\n";
$prog eq $sightlystr or print "not ";
print "ok 37\n";

# One less  abc ------------------------------------

$prog = sightly({ Width         => $exact-1,
                  SourceString  => $srcstr,
                  FillerVar     => '#',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 38\n";
$outstr eq "abc\n" or print "not ";
print "ok 39\n";
$nlf = $prog =~ tr/\n//;
$nlf == 2 or print "not ";
print "ok 40\n";
$last = chop($prog);
$last eq "\n" or print "not ";
print "ok 41\n";
@lines = split(/\n/, $prog);
scalar(@lines) == 2 or print "not ";
print "ok 42\n";
$fchar = substr($lines[1], 0, 1);
$fchar eq ')' or print "not ";
print "ok 43\n";
length($prog) == 2*($exact-1)+1 or print "not ";
print "ok 44\n";
$nprog = $lines[0] . $fchar;
$nprog eq $sightlystr or print "not ";
print "ok 45\n";

exit 0;

# --------------------------------------------------
unlink $tmpf;
