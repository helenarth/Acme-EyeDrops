use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

# --------------------------------------------------

print "1..9\n";

my $larrystr = get_eye_string('larry');
my $damianstr = get_eye_string('damian');
my $tmpf = 'bill.tmp';

# Larry helloworld.pl ------------------------------

my $prog = sightly({ Shape         => 'larry',
                     SourceFile    => 'demo/helloworld.pl',
                     Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 1\n";
$outstr eq "hello world\n" or print "not ";
print "ok 2\n";
$prog =~ tr/!-~/#/;
$prog eq $larrystr or print "not ";
print "ok 3\n";

# larry/damian helloworld.pl -------------------------

$prog = sightly({ Shape         => 'larry,damian',
                  SourceFile    => 'demo/helloworld.pl',
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
my $tt = $larrystr . $damianstr;
$prog eq $tt or print "not ";
print "ok 6\n";

# damian.larry helloworld.pl -------------------------

$prog = sightly({ Shape         => 'damian,larry',
                  SourceFile    => 'demo/helloworld.pl',
                  Regex         => 1 } );
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
$outstr = `$^X -w -Mstrict $tmpf`;
$rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 7\n";
$outstr eq "hello world\n" or print "not ";
print "ok 8\n";
$prog =~ tr/!-~/#/;
$tt = $damianstr . $larrystr;
$prog eq $tt or print "not ";
print "ok 9\n";

# -------------------------------------------------

unlink $tmpf;
