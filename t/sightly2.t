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

print "1..12\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $hellofile = 'helloworld.pl';
my $larrystr = get_eye_string('larry');
my $damianstr = get_eye_string('damian');
my $tmpf = 'bill.tmp';

build_file($hellofile, $hellostr);

# Larry helloworld.pl ------------------------------

my $prog = sightly({ Shape         => 'larry',
                     SourceFile    => $hellofile,
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
                  SourceFile    => $hellofile,
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

# damian/larry helloworld.pl -------------------------

$prog = sightly({ Shape         => 'damian,larry',
                  SourceFile    => $hellofile,
                  Gap           => 2,
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
$tt = join("\n\n", $damianstr, $larrystr);
$prog eq $tt or print "not ";
print "ok 9\n";

# Test trailing spaces in shape ----------------------

my $shape = "####################   \n   \n########## \n" x 11;
$prog = sightly({ ShapeString   => $shape,
                  SourceFile    => $hellofile,
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
$prog eq $shape or print "not ";
print "ok 12\n";

# -------------------------------------------------

unlink $tmpf;
unlink $hellofile;

exit 0;
