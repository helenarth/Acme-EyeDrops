#!/usr/bin/perl
# reshape.t

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

# -------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d; close(F);
}

# --------------------------------------------------

print "1..27\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $camelstr = get_eye_string('camel');
my $tmpf = 'bill.tmp';

# --------------------------------------------------

my $itest = 0;
my $prog;

sub test_one {
   my ($e, $ostr) = @_;
   build_file($tmpf, $prog);
   my $outstr = `$^X -w -Mstrict $tmpf`;
   my $rc = $? >> 8;
   $rc == 0 or print "not ";
   ++$itest; print "ok $itest - $e rc\n";
   $outstr eq $ostr or print "not ";
   ++$itest; print "ok $itest - $e output\n";
}

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Expand        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $bigprog = $prog;
test_one('big camel', "hello world\n");
$bigprog =~ tr/!-~/#/;
$bigprog eq $camelstr and print "not ";
++$itest; print "ok $itest - bigprog\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $bigprog,
                  SourceString  => $hellostr,
                  Reduce        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('camel', "hello world\n");
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
++$itest; print "ok $itest - prog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  InformHandler => sub {},
                  Regex         => 1 } );
my $rotprog = $prog;
test_one('rot 90 camel', "hello world\n");
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
++$itest; print "ok $itest - prog\n";

# -------------------------------------------------

$prog = sightly({ Shape          => 'camel',
                  SourceString  => $hellostr,
                  Rotate         => 90,
                  TrailingSpaces => 1,
                  InformHandler => sub {},
                  Regex          => 1 } );
$rotprog = $prog;
test_one('rot 90 trail camel', "hello world\n");
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
++$itest; print "ok $itest - prog\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $rotprog,
                  SourceString  => $hellostr,
                  Rotate        => 270,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('rot 270 camel', "hello world\n");
$prog =~ tr/!-~/#/;
$prog eq $bigprog or print "not ";
++$itest; print "ok $itest - bigprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  RotateType    => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
$rotprog = $prog;
test_one('rot 90 camel', "hello world\n");
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
++$itest; print "ok $itest - bigprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 90,
                  RotateType    => 0,
                  Reduce        => 1,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('rot 90 camel', "hello world\n");
$prog =~ tr/!-~/#/;
$prog eq $rotprog or print "not ";
++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $hellostr,
                  Rotate        => 180,
                  InformHandler => sub {},
                  Regex         => 1 } );
$rotprog = $prog;
test_one('rot 180 camel', "hello world\n");
$rotprog =~ tr/!-~/#/;
$rotprog eq $camelstr and print "not ";
++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

$prog = sightly({ ShapeString   => $rotprog,
                  SourceString  => $hellostr,
                  Rotate        => 180,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('rot 180 camel', "hello world\n");
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
++$itest; print "ok $itest - rotprog\n";

# -------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";

exit 0;
