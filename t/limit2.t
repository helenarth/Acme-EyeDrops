use strict;
use Acme::EyeDrops qw(sightly);

print "1..44\n";

my $tmpf = 'bill.tmp';

sub do_one_empty_limit {
   my ($cnt, $shapestr) = @_;
   my $prog = sightly( { ShapeString => $shapestr } );
   open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
   print TT $prog;
   close(TT);
   my $outstr = `$^X -w -Mstrict $tmpf`;
   my $rc = $? >> 8;
   $rc == 0 or print "not ";
   print "ok $cnt\n"; ++$cnt;
   $outstr eq "" or print "not ";
   print "ok $cnt\n"; ++$cnt;
   my $nlf = $prog =~ tr/\n//;
   $nlf == 1 or print "not ";
   print "ok $cnt\n"; ++$cnt;
   $prog =~ tr/!-~/#/;
   $prog eq $shapestr or print "not ";
   print "ok $cnt\n"; ++$cnt;
}

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

# more invalid program tests --------------------------

# This one failed prior to EyeDrops version 1.17.
do_one_empty_limit( 9, "############  ######  ###  ###\n");

do_one_empty_limit(13, "############  ###  ###  #\n");
do_one_empty_limit(17, "############  #####  ###  #\n");
do_one_empty_limit(21, "############  ###  ####  #\n");
do_one_empty_limit(25, "############  #\n");
do_one_empty_limit(29, "############  ##\n");
do_one_empty_limit(33, "############  ###\n");
do_one_empty_limit(37, "############  ####\n");
do_one_empty_limit(41, "############\n");

# -----------------------------------------------------

unlink $tmpf;
