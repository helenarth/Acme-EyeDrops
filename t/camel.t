use strict;
use Acme::EyeDrops qw(sightly get_eye_string reflect_shape);

# -------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

print "1..16\n";

my $camelstr = get_eye_string('camel');
my $camel_Y_str = $camelstr;
$camel_Y_str =~ tr/#/Y/;
my $buffystr = get_eye_string('buffy2');
my $buffymirrorstr = reflect_shape($buffystr);

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

$src = <<'END_SRC_STR';
$~=uc shift;$:=pop||'#';open$%;chop(@~=<0>);$~=~R&&
(@~=map{$-=$_+$_;join'',map/.{$-}(.)/,@~}$%..33);
$|--&$~=~H&&next,$~!~Q&&eval"y, ,\Q$:\E,c",$~=~I&&
eval"y, \Q$:\E,\Q$:\E ,",$~=~M&&($_=reverse),
print$~=~V?/(.).?/g:$_,$/for$~=~U?reverse@~:@~
END_SRC_STR
$src =~ tr/\n//d;
$prog1 = sightly( { Regex         => 1,
                    Compact       => 1,
                    Shape         => 'camel',
                    SourceString  => $src } );
@a = split(/\n/, $prog1);
$max = 0; length > $max and $max = length for @a;
$_ .= ' ' x ($max - length) for @a;
$camelprog = (' ' x ($max+2)) . "\n";
$camelprog .= " $_ \n" for @a;
$camelprog .= (' ' x ($max+2)) . "\n";
$camelprogstr = $camelprog;
$camelprogstr =~ tr/!-~/#/;
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $camelprog;
close(TT);

# -------------------------------------------------

$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 6\n";
$outstr eq $camelprogstr or print "not ";
print "ok 7\n";
$outstr =~ s/^ //mg;
$outstr =~ s/ +$//mg;
$outstr =~ s/\n//; chop $outstr;
$outstr eq $camelstr or print "not ";
print "ok 8\n";

# -------------------------------------------------

$outstr = `$^X -w -Mstrict $tmpf q`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 9\n";
$outstr eq $camelprog or print "not ";
print "ok 10\n";

# -------------------------------------------------

$camelprogstr =~ tr/#/Y/;
$outstr = `$^X -w -Mstrict $tmpf Y Y`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 11\n";
$outstr eq $camelprogstr or print "not ";
print "ok 12\n";
$outstr =~ s/^ //mg;
$outstr =~ s/ +$//mg;
$outstr =~ s/\n//; chop $outstr;
$outstr eq $camel_Y_str or print "not ";
print "ok 13\n";

# -------------------------------------------------
# -------------------------------------------------

$src = <<'END_SRC_STR';
open$[;chop,($==y===c)>$-&&($-=$=)for@:=<0>;
print$"x-(y---c-$-).reverse.$/for@:
END_SRC_STR
my $buffyprog = sightly( { Regex         => 1,
                           Compact       => 1,
                           Shape         => 'buffy2',
                           SourceString  => $src } );
my $buffyprogstr = $buffyprog;
$buffyprogstr =~ tr/!-~/#/;
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $buffyprog;
close(TT);

# -------------------------------------------------

$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 14\n";
$outstr =~ tr/!-~/#/;
$outstr eq $buffyprogstr and print "not ";
print "ok 15\n";
$outstr =~ s/ +$//mg;
$outstr eq $buffymirrorstr or print "not ";
print "ok 16\n";

# -------------------------------------------------

unlink $tmpf;

exit 0;
