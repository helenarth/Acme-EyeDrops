use strict;
use Acme::EyeDrops qw(sightly);

print "1..5\n";

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

# -------------------------------------------------

my $src = <<'END_SRC';
$~=uc pop;open$%;chop(@~=<0>);$~=~R&&(@~=map{$-=$_+$_;join'',
map/.{$-}(.)/,@~}$%..$~[8]=~y~~~c/2);$~!~Q&&y,!-~,#,,$~=~I&&
y~ #~# ~,print$~=~M?~~reverse:$_,$/for$~=~U?reverse@~:@~
END_SRC
$src =~ tr/\n//d;
my $prog1 = sightly( { Regex         => 1,
                       Shape         => 'camel',
                       SourceString  => $src } );
my @a = split(/\n/, $prog1);
my $max = 0; length > $max and $max = length for @a;
$_ .= ' ' x ($max - length) for @a;
my $camelprog = (' ' x ($max+2)) . "\n";
$camelprog .= " $_ \n" for @a;
$camelprog .= (' ' x ($max+2)) . "\n";
my $camelprogstr = $camelprog;
$camelprogstr =~ tr/!-~/#/;
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $camelprog;
close(TT);

# -------------------------------------------------

my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 1\n";
$outstr eq $camelprogstr or print "not ";
print "ok 2\n";
$outstr =~ s/^ //mg;
$outstr =~ s/ +$//mg;
$outstr =~ s/\n//; chop $outstr;
$outstr eq $camelstr or print "not ";
print "ok 3\n";

# -------------------------------------------------

$outstr = `$^X -w -Mstrict $tmpf q`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 4\n";
$outstr eq $camelprog or print "not ";
print "ok 5\n";

# -------------------------------------------------

unlink $tmpf;
