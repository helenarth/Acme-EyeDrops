use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

# --------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

print "1..6\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $camelstr = get_eye_string('camel');
$camelstr .= get_eye_string('window');
my $tmpf = 'bill.tmp';

# Run camel,window helloworld.pl on itself twice ---

my $prog = sightly({ Shape         => 'camel,window',
                     SourceString  => $hellostr,
                     Regex         => 1 } );
my $progorig = $prog;
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
$prog eq $camelstr or print "not ";
print "ok 3\n";

$prog = sightly({ Shape         => 'camel,window',
                  SourceString  => $progorig,
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
my $teststr = $camelstr x 16;
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
print "ok 6\n";

# --------------------------------------------------

unlink $tmpf;

exit 0;
