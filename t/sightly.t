use strict;
use Acme::EyeDrops qw(sightly get_eye_string make_siertri);

# --------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

print "1..35\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $helloteststr = <<'HELLOTEST';
# Just a test.
use strict;
for my $i (0..3) {
   print "hello test $i\n";
}
HELLOTEST
my $camelstr = get_eye_string('camel');
my $umlstr = get_eye_string('uml');
my $windowstr = get_eye_string('window');
my $japhstr = get_eye_string('japh');
my $yanick4str = get_eye_string('yanick4');
my $siertristr = make_siertri(5);
my $tmpf = 'bill.tmp';

# Camel helloworld.pl ------------------------------

my $prog = sightly({ Shape         => 'camel',
                     SourceString  => $hellostr,
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 1\n";
$outstr eq "hello world\n" or print "not ";
print "ok 2\n";
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
print "ok 3\n";

# uml/window helloworld.pl -------------------------

$prog = sightly({ Shape         => 'uml,window',
                  SourceString  => $hellostr,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 4\n";
$outstr eq "hello world\n" or print "not ";
print "ok 5\n";
$prog =~ tr/!-~/#/;
$prog eq "$umlstr$windowstr" or print "not ";
print "ok 6\n";

# Text string print --------------------------------

my $srcstr = "Bill Gates is a pest!\n";
$prog = sightly({ Shape         => 'window',
                  SourceString  => $srcstr,
                  Regex         => 1,
                  Print         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 7\n";
$outstr eq $srcstr or print "not ";
print "ok 8\n";
$prog =~ tr/!-~/#/;
$prog eq $windowstr or print "not ";
print "ok 9\n";

# Binary encode/decode -----------------------------

my $encodestr = qq#binmode(STDOUT);print eval '"'.\n\n\n#;
$encodestr =~ tr/!-~/#/;
$encodestr .= $camelstr x 5;
$srcstr = join("", map {chr} 0..255);
$prog = sightly({ Shape         => 'camel',
                  SourceString  => $srcstr,
                  Binary        => 1,
                  Regex         => 0,
                  Print         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
# This seems to stop on CTRL-Z on Windows!
# Something to do with binmode ??
#   $outstr = `$^X -w -Mstrict $tmpf`;
# so use a temporary file instead.
my $tmpf2 = 'bill2.tmp';
system("$^X -w -Mstrict $tmpf >$tmpf2");
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 10\n";
open(TT, $tmpf2) or die "open '$tmpf2': $!";
binmode(TT);
{
   local $/ = undef; $outstr = <TT>;
}
close(TT);
$outstr eq $srcstr or print "not ";
print "ok 11\n";
$prog =~ tr/!-~/#/;
$prog eq $encodestr or print "not ";
print "ok 12\n";

# Self-printing JAPH -------------------------------

my $src = <<'PROG';
open 0;
$/ = undef;
$x = <0>;
close 0;
$x =~ tr/!-~/#/;
print $x;
PROG
$prog = sightly({ Shape         => 'japh',
                  SourceString  => $src,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 13\n";
$outstr eq $japhstr or print "not ";
print "ok 14\n";

# Camel helloworld.pl (FillerVar=';')---------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  FillerVar     => ';',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 15\n";
$outstr eq "hello world\n" or print "not ";
print "ok 16\n";
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
print "ok 17\n";

# Camel helloworld.pl (FillerVar=';#')--------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  FillerVar     => ';#',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 18\n";
$outstr eq "hello world\n" or print "not ";
print "ok 19\n";
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
print "ok 20\n";

# Camel helloworld.pl (FillerVar='')----------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  FillerVar     => '',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 21\n";
$outstr eq "hello world\n" or print "not ";
print "ok 22\n";
length($prog) eq 472 or print "not ";
print "ok 23\n";

# Yanick4 hellotest.pl -----------------(3 shapes)--

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 24\n";
$outstr eq "hello test 0\nhello test 1\nhello test 2\nhello test 3\n"
   or print "not ";
print "ok 25\n";
$prog =~ tr/!-~/#/;
$prog eq $yanick4str x 3 or print "not ";
print "ok 26\n";

# Yanick4 hellotest.pl (FillerVar=';')--(3 shapes)--

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  FillerVar     => ';',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 27\n";
$outstr eq "hello test 0\nhello test 1\nhello test 2\nhello test 3\n"
   or print "not ";
print "ok 28\n";
$prog =~ tr/!-~/#/;
$prog eq $yanick4str x 3 or print "not ";
print "ok 29\n";

# Yanick4 hellotest.pl (FillerVar='')---(3 shapes)--

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  FillerVar     => '',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 30\n";
$outstr eq "hello test 0\nhello test 1\nhello test 2\nhello test 3\n"
   or print "not ";
print "ok 31\n";
$prog =~ tr/!-~/#/;
$prog eq $yanick4str x 3 and print "not ";
print "ok 32\n";

# siertri hellotest.pl (FillerVar=';')--(3 shapes)--

$prog = sightly({ Shape         => 'siertri',
                  Width         => 5,
                  SourceString  => $helloteststr,
                  FillerVar     => ';',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 33\n";
$outstr eq "hello test 0\nhello test 1\nhello test 2\nhello test 3\n"
   or print "not ";
print "ok 34\n";
$prog =~ tr/!-~/#/;
$prog eq $siertristr x 5 or print "not ";
print "ok 35\n";

# --------------------------------------------------

unlink $tmpf;
unlink $tmpf2;

exit 0;
