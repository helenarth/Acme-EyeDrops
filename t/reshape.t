use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

# -------------------------------------------------

print "1..24\n";

my $camelstr = get_eye_string('camel');
my $tmpf = 'bill.tmp';

# -------------------------------------------------

my $bigprog = sightly({ Shape         => 'camel',
                        SourceFile    => 'demo/helloworld.pl',
                        Expand        => 1,
                        Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $bigprog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 1\n";
$outstr eq "hello world\n" or print "not ";
print "ok 2\n";
$bigprog =~ tr/!-~/#/;
$bigprog eq $camelstr and print "not ";
print "ok 3\n";

# -------------------------------------------------

my $prog = sightly({ ShapeString   => $bigprog,
                     SourceFile    => 'demo/helloworld.pl',
                     Reduce        => 1,
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
$prog eq $camelstr or print "not ";
print "ok 6\n";

# -------------------------------------------------

my $rotprog = sightly({ Shape         => 'camel',
                        SourceFile    => 'demo/helloworld.pl',
                        Rotate        => 90,
                        Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $rotprog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 7\n";
$outstr eq "hello world\n" or print "not ";
print "ok 8\n";
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
print "ok 9\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $rotprog,
                  SourceFile    => 'demo/helloworld.pl',
                  Rotate        => 270,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 10\n";
$outstr eq "hello world\n" or print "not ";
print "ok 11\n";
$prog =~ tr/!-~/#/;
$prog eq $bigprog or print "not ";
print "ok 12\n";

# -------------------------------------------------

$rotprog = sightly({ Shape         => 'camel',
                     SourceFile    => 'demo/helloworld.pl',
                     Rotate        => 90,
                     RotateType    => 1,
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $rotprog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 13\n";
$outstr eq "hello world\n" or print "not ";
print "ok 14\n";
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
print "ok 15\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceFile    => 'demo/helloworld.pl',
                  Rotate        => 90,
                  RotateType    => 0,
                  Reduce        => 1,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 16\n";
$outstr eq "hello world\n" or print "not ";
print "ok 17\n";
$prog =~ tr/!-~/#/;
$prog eq $rotprog or print "not ";
print "ok 18\n";

# -------------------------------------------------

$rotprog = sightly({ Shape         => 'camel',
                     SourceFile    => 'demo/helloworld.pl',
                     Rotate        => 180,
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $rotprog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 19\n";
$outstr eq "hello world\n" or print "not ";
print "ok 20\n";
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
print "ok 21\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $rotprog,
                  SourceFile    => 'demo/helloworld.pl',
                  Rotate        => 180,
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 22\n";
$outstr eq "hello world\n" or print "not ";
print "ok 23\n";
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
print "ok 24\n";

# -------------------------------------------------

unlink $tmpf;
