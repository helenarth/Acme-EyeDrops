#!/usr/bin/perl
# recur.t

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d; close(F);
}

# --------------------------------------------------

print "1..6\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $camelstr = get_eye_string('camel');
$camelstr .= get_eye_string('window');
my $tmpf = 'bill.tmp';

# -------------------------------------------------

my $itest = 0;
my $prog;

# Run camel,window helloworld.pl on itself twice ---

$prog = sightly({ Shape         => 'camel,window',
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
my $progorig = $prog;
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - twice rc\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest - twice output\n";
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
++$itest; print "ok $itest - twice shape\n";

$prog = sightly({ Shape         => 'camel,window',
                  SourceString  => $progorig,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - twice rc\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest - twice output\n";
my $teststr = $camelstr x 16;
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
++$itest; print "ok $itest - twice shape\n";

# --------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";

exit 0;
