#!/usr/bin/perl
# camel.t

use strict;
use Acme::EyeDrops qw(sightly get_eye_string reflect_shape);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d; close(F);
}

# --------------------------------------------------

print "1..11\n";

my $camelstr = get_eye_string('camel');
my $camel_Y_str = $camelstr;
$camel_Y_str =~ tr/#/Y/;
my $buffystr = get_eye_string('buffy2');
my $buffymirrorstr = reflect_shape($buffystr);

my $tmpf = 'bill.tmp';

# -------------------------------------------------

my $itest = 0;
my $prog;

# -------------------------------------------------
# Test 12032 camels example.

$prog = sightly( { Regex          => 1,
                   Compact        => 1,
                   RemoveNewlines => 1,
                   BorderGap      => 1,
                   Shape          => 'camel',
                   InformHandler  => sub {},
                   SourceString   => <<'END_SRC_STR' } );
$~=uc shift;$:=pop||'#';open$%;chop(@~=<0>);$~=~R&&
(@~=map{$-=$_+$_;join'',map/.{$-}(.)/,@~}$%..33);
$|--&$~=~H&&next,$~!~Q&&eval"y, ,\Q$:\E,c",$~=~I&&
eval"y, \Q$:\E,\Q$:\E ,",$~=~M&&($_=reverse),
print$~=~V?/(.).?/g:$_,$/for$~=~U?reverse@~:@~
END_SRC_STR
build_file($tmpf, $prog);
my $camelprog = my $camelprogstr = $prog;
$camelprogstr =~ tr/!-~/#/;

# -------------------------------------------------

my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - 12032 camels rc\n";
$outstr eq $camelprogstr or print "not ";
++$itest; print "ok $itest - 12032 camels shape\n";
$outstr =~ s/^ //mg;
$outstr =~ s/ +$//mg;
$outstr =~ s/\n//; chop $outstr;
$outstr eq $camelstr or print "not ";
++$itest; print "ok $itest - 12032 camels shape trail\n";

# -------------------------------------------------

$outstr = `$^X -w -Mstrict $tmpf q`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - 12032 camels quine rc\n";
$outstr eq $camelprog or print "not ";
++$itest; print "ok $itest - 12032 camels quine shape\n";

# -------------------------------------------------

$camelprogstr =~ tr/#/Y/;
$outstr = `$^X -w -Mstrict $tmpf Y Y`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - 12032 camels Y rc\n";
$outstr eq $camelprogstr or print "not ";
++$itest; print "ok $itest - 12032 camels Y shape\n";
$outstr =~ s/^ //mg;
$outstr =~ s/ +$//mg;
$outstr =~ s/\n//; chop $outstr;
$outstr eq $camel_Y_str or print "not ";
++$itest; print "ok $itest - 12032 camels Y shape trail\n";

# -------------------------------------------------
# Test Buffy looking in the mirror example.

my $src = <<'END_SRC_STR';
open$[;chop,($==y===c)>$-&&($-=$=)for@:=<0>;
print$"x-(y---c-$-).reverse.$/for@:
END_SRC_STR
$prog = sightly( { Regex         => 1,
                   Compact       => 1,
                   Shape         => 'buffy2',
                   InformHandler => sub {},
                   SourceString  => $src } );
build_file($tmpf, $prog);
my $buffyprogstr = my $buffyprog = $prog;
$buffyprogstr =~ tr/!-~/#/;

# -------------------------------------------------

$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - buffy rc\n";
$outstr =~ tr/!-~/#/;
$outstr eq $buffyprogstr and print "not ";
++$itest; print "ok $itest - buffy shape\n";
$outstr =~ s/ +$//mg;
$outstr eq $buffymirrorstr or print "not ";
++$itest; print "ok $itest - buffy shape mirror\n";

# -------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";

exit 0;
