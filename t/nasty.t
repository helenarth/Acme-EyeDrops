use strict;
use Acme::EyeDrops qw(sightly);

print "1..7\n";

sub get_shape_str {
   my $sfile = "lib/Acme/$_[0].eye";
   open(TT, $sfile) or die "open '$sfile': $!";
   local $/ = undef;
   my $str = <TT>;
   close(TT);
   return $str;
}

my $camelstr = get_shape_str('camel');
my $tmpf = 'bill.tmp';
my $tmpf2 = 'bill2.tmp';

# Camel hellodie.pl --------------------------------

# This tests catching die inside eval.

my $evalstr = qq#eval eval '"'.\n\n\n#;
$evalstr =~ tr/!-~/#/;
my $diestr = qq#\n\n\n;die \$\@ if \$\@\n#;
$diestr =~ tr/!-~/#/;
my $teststr = $evalstr . $camelstr . $diestr;
my $srcstr = 'die "hello die\\n";';
my $prog = sightly({ Shape         => 'camel',
                     SourceString  => $srcstr,
                     Regex         => 0,
                     TrapEvalDie   => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w $tmpf 2>$tmpf2`;
my $rc = $? >> 8;
$rc == 0 and print "not ";
print "ok 1\n";
$outstr eq "" or print "not ";
print "ok 2\n";
open(TT, $tmpf2) or die "open '$tmpf2': $!";
{
   local $/ = undef; $outstr = <TT>;
}
close(TT);
$outstr eq "hello die\n" or print "not ";
print "ok 3\n";
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
print "ok 4\n";

# Camel beginend.pl --------------------------------

# This tests BEGIN/END blocks.

$evalstr = qq#eval eval '"'.\n\n\n#;
$evalstr =~ tr/!-~/#/;
$teststr = $evalstr . $camelstr;
$srcstr = qq#BEGIN {print "begin\\n"}\n# .
          qq#END {print "end\\n"}\n# .
          qq#print "line1\\nline2\\n";\n#;
$prog = sightly({ Shape         => 'camel',
                  SourceString  => $srcstr,
                  Regex         => 0,
                  TrapEvalDie   => 0 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 5\n";
$outstr eq "begin\nline1\nline2\nend\n" or print "not ";
print "ok 6\n";
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
print "ok 7\n";

# --------------------------------------------------

unlink $tmpf;
unlink $tmpf2;
