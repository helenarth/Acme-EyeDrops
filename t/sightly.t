use strict;
use Acme::EyeDrops qw(sightly);

print "1..14\n";

sub get_shape_str {
   my $sfile = "lib/Acme/$_[0].eye";
   open(TT, $sfile) or die "open '$sfile': $!";
   local $/ = undef;
   my $str = <TT>;
   close(TT);
   return $str;
}

my $camelstr = get_shape_str('camel');
my $umlstr = get_shape_str('uml');
my $windowstr = get_shape_str('window');
my $japhstr = get_shape_str('japh');
my $tmpf = 'bill.tmp';

# Camel helloworld.pl ------------------------------

my $prog = sightly({ Shape         => 'camel',
                     SourceFile    => 'demo/helloworld.pl',
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w $tmpf`;
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
                  SourceFile    => 'demo/helloworld.pl',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w $tmpf`;
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
$outstr = `$^X -w $tmpf`;
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
$encodestr .= $camelstr x 6;
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
#   $outstr = `$^X -w $tmpf`;
# so use a temporary file instead.
my $tmpf2 = 'bill2.tmp';
system("$^X -w $tmpf >$tmpf2");
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

unlink $tmpf;
unlink $tmpf2;

# Self-printing JAPH -------------------------------

$tmpf = 'japh.tmp';
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
$outstr = `$^X -w $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 13\n";
$outstr eq $japhstr or print "not ";
print "ok 14\n";
