use strict;
use Acme::EyeDrops qw(sightly);

my $have_stderr_redirect = 1;
if ($^O eq 'MSWin32') {
   Win32::IsWinNT() or $have_stderr_redirect = 0;
}
print $have_stderr_redirect ? "1..7\n" : "1..3\n";

sub get_shape_str {
   my $sfile = "lib/Acme/$_[0].eye";
   local *TT;
   open(TT, $sfile) or die "open '$sfile': $!";
   local $/ = undef;
   my $str = <TT>;
   close(TT);
   return $str;
}

my $camelstr = get_shape_str('camel');
my $tmpf = 'bill.tmp';

# Camel beginend.pl --------------------------------

# This tests BEGIN/END blocks.

my $evalstr = qq#eval eval '"'.\n\n\n#;
$evalstr =~ tr/!-~/#/;
my $teststr = $evalstr . $camelstr;
my $srcstr = qq#BEGIN {print "begin\\n"}\n# .
             qq#END {print "end\\n"}\n# .
             qq#print "line1\\nline2\\n";\n#;
my $prog = sightly({ Shape         => 'camel',
                     SourceString  => $srcstr,
                     Regex         => 0,
                     TrapEvalDie   => 0 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 1\n";
$outstr eq "begin\nline1\nline2\nend\n" or print "not ";
print "ok 2\n";
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
print "ok 3\n";

unless ($have_stderr_redirect) {
   unlink $tmpf;
   exit(0);
}

# Camel hellodie.pl --------------------------------

# This tests catching die inside eval.
# This test requires the ability to re-direct stderr,
# conspiciously absent from Win 95/98 family.

my $tmpf2 = 'bill2.tmp';
$evalstr = qq#eval eval '"'.\n\n\n#;
$evalstr =~ tr/!-~/#/;
my $diestr = qq#\n\n\n;die \$\@ if \$\@\n#;
$diestr =~ tr/!-~/#/;
$teststr = $evalstr . $camelstr . $diestr;
$srcstr = 'die "hello die\\n";';
$prog = sightly({ Shape         => 'camel',
                  SourceString  => $srcstr,
                  Regex         => 0,
                  TrapEvalDie   => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf 2>$tmpf2`;
$rc = $? >> 8;
$rc == 0 and print "not ";
print "ok 4\n";
$outstr eq "" or print "not ";
print "ok 5\n";
open(TT, $tmpf2) or die "open '$tmpf2': $!";
{
   local $/ = undef; $outstr = <TT>;
}
close(TT);
$outstr eq "hello die\n" or print "not ";
print "ok 6\n";
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
print "ok 7\n";
unlink $tmpf2;

# --------------------------------------------------

unlink $tmpf;
