use strict;
use Acme::EyeDrops qw(sightly get_eye_string pour_text);

# --------------------------------------------------

print "1..29\n";

my $snow = get_eye_string('snow');

my $src = <<'SNOWING';
$_=q~vZvZ&%('$&"'"&(&"&$&"'"&$Z$#$$$#$%$&"'"&(&#
%$&"'"&#Z#$$$#%#%$%$%$%(%%%#%$%$%#Z"%*#$%$%$%$%(%%%#%$%$
%#Z"%,($%$%$%(%%%#%$%$%#Z"%*%"%$%$%$%(%%%#%$%$%#Z#%%"#%#%
$%$%$%$##&#%$%$%$%#Z$&""$%"&$%$%$%#%"%"&%%$%$%#Z%&%&#
%"'"'"'###%*'"'"'"ZT%?ZT%?ZS'>Zv~;
s;\s;;g;
$;='@,=map{$.=$";join"",map((($.^=O)x(-33+ord)),/./g),$/}split+Z;
s/./(rand)<.2?"o":$"/egfor@;=((5x84).$/)x30;map{
system$^O=~W?CLS:"clear";print@;;splice@;,-$_,2,pop@,;
@;=($/,@;);sleep!$%}2..17';
$;=~s;\s;;g;eval$;
SNOWING

# -------------------------------------------------

my $snowflake = pour_text($snow, "",  1, '#');
$snowflake eq $snow or print "not ";
print "ok 1\n";

# -------------------------------------------------

$snowflake = pour_text($snow, $src,  1, "");
my $t = $snowflake; $t =~ s/\s+//g;
my $v = $src; $v =~ s/\s+//g;
substr($t, 0, length($v)) eq $v or print "not ";
print "ok 2\n";
substr($t, length($v)) eq '' or print "not ";
print "ok 3\n";

# -------------------------------------------------

$snowflake = pour_text($snow, $src,  1, '#');
$t = $snowflake;
$t =~ tr/!-~/#/;
$t eq $snow or print "not ";
print "ok 4\n";
$t = $snowflake; $t =~ s/\s+//g;
$v = $src; $v =~ s/\s+//g;
substr($t, 0, length($v)) eq $v or print "not ";
print "ok 5\n";
substr($t, length($v)) eq '#' x (length($t)-length($v)) or print "not ";
print "ok 6\n";

# -------------------------------------------------

$snowflake = sightly( { Shape         => 'snow',
                        SourceString  => $src,
                        Text          => 1,
                        TextFiller    => '#' } );
$t = $snowflake;
$t =~ tr/!-~/#/;
$t eq $snow or print "not ";
print "ok 7\n";
$t = $snowflake; $t =~ s/\s+//g;
$v = $src; $v =~ s/\s+//g;
substr($t, 0, length($v)) eq $v or print "not ";
print "ok 8\n";
substr($t, length($v)) eq '#' x (length($t)-length($v)) or print "not ";
print "ok 9\n";

# -------------------------------------------------

my $shape = "## ###\n";
my $p = pour_text($shape, "", 1, "");
$p eq "\n" or print "not ";
print "ok 10\n";
$p = pour_text($shape, 'X', 1, "");
$p eq "X\n" or print "not ";
print "ok 11\n";
$p = pour_text($shape, 'XX', 1, "");
$p eq "XX\n" or print "not ";
print "ok 12\n";
$p = pour_text($shape, 'XXX', 1, "");
$p eq "XX X\n" or print "not ";
print "ok 13\n";
$p = pour_text($shape, 'XXXXX', 1, "");
$p eq "XX XXX\n" or print "not ";
print "ok 14\n";
$p = pour_text($shape, 'XXXXXX', 1, "");
$p eq "XX XXX\n\nX\n" or print "not ";
print "ok 15\n";

# -------------------------------------------------

$p = pour_text($shape, '', 2, '#');
$p eq "## ###\n" or print "not ";
print "ok 16\n";
$p = pour_text($shape, 'X', 2, '#');
$p eq "X# ###\n" or print "not ";
print "ok 17\n";
$p = pour_text($shape, 'XX', 2, '#');
$p eq "XX ###\n" or print "not ";
print "ok 18\n";
$p = pour_text($shape, 'XXX', 2, '#');
$p eq "XX X##\n" or print "not ";
print "ok 19\n";
$p = pour_text($shape, 'XXXX', 2, '#');
$p eq "XX XX#\n" or print "not ";
print "ok 20\n";
$p = pour_text($shape, 'XXXXX', 2, '#');
$p eq "XX XXX\n" or print "not ";
print "ok 21\n";
$p = pour_text($shape, 'XXXXXX', 2, '#');
$p eq "XX XXX\n\n\nX# ###\n" or print "not ";
print "ok 22\n";

# -------------------------------------------------

$p = pour_text($shape, 'X', 3, 'abc');
$p eq "Xa bca\n" or print "not ";
print "ok 23\n";
$p = pour_text($shape, 'X', 3, 'abcd');
$p eq "Xa bcd\n" or print "not ";
print "ok 24\n";
$p = pour_text($shape, 'XXXXX', 3, 'abc');
$p eq "XX XXX\n" or print "not ";
print "ok 25\n";
$p = pour_text($shape, '1234567', 3, 'abc');
$p eq "12 345\n\n\n\n67 abc\n" or print "not ";
print "ok 26\n";

# -------------------------------------------------

$p = sightly( { SourceString  => 'knob',
                Width         => 1,
                Text          => 1,
                TextFiller    => '#' } );
$p eq "k\nn\no\nb\n" or print "not ";
print "ok 27\n";

$p = sightly( { SourceString  => 'knob',
                Width         => 3,
                Text          => 1,
                TextFiller    => '#' } );
$p eq "kno\nb##\n" or print "not ";
print "ok 28\n";

$p = sightly( { SourceString  => 'knob',
                Width         => 4,
                Text          => 1,
                TextFiller    => '#' } );
$p eq "knob\n" or print "not ";
print "ok 29\n";
