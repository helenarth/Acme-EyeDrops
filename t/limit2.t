use strict;
use Acme::EyeDrops qw(sightly);

print "1..8\n";

my $tmpf = 'bill.tmp';

my $srcstr = '$x=9';

my $bugshape = 
'#######################################################' .
'#######################################################' .
"\n" . "# # #\n";

my $onetoomanyshape = 
'#######################################################' .
'#######################################################' .
"\n" . "# # # #\n";

# one too many bug ------------------------------------

my $prog = sightly({ ShapeString   => $onetoomanyshape,
                     SourceString  => $srcstr,
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 1\n";
$outstr eq "" or print "not ";
print "ok 2\n";
my $nlf = $prog =~ tr/\n//;
$nlf == 2 or print "not ";
print "ok 3\n";
$prog =~ tr/!-~/#/;
$prog eq $onetoomanyshape or print "not ";
print "ok 4\n";

# invalid program bug ---------------------------------

$prog = sightly({ ShapeString   => $bugshape,
                  SourceString  => $srcstr,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 5\n";
$outstr eq "" or print "not ";
print "ok 6\n";
$nlf = $prog =~ tr/\n//;
$nlf == 2 or print "not ";
print "ok 7\n";
$prog =~ tr/!-~/#/;
$prog eq $bugshape or print "not ";
print "ok 8\n";

# -----------------------------------------------------

unlink $tmpf;
