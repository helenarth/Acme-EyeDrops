use strict;
use Acme::EyeDrops qw(sightly);

print "1..6\n";

sub get_shape_str {
   my $sfile = "lib/Acme/$_[0].eye";
   open(TT, $sfile) or die "open '$sfile': $!";
   local $/ = undef;
   my $str = <TT>;
   close(TT);
   return $str;
}

my $camelstr = get_shape_str('camel');
$camelstr .= get_shape_str('window');
my $tmpf = 'bill.tmp';

# Run camel,window helloworld.pl on itself twice ---

my $prog = sightly({ Shape         => 'camel,window',
                     SourceFile    => 'demo/helloworld.pl',
                     Regex         => 1 } );
my $progorig = $prog;
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

$prog = sightly({ Shape         => 'camel,window',
                  SourceString  => $progorig,
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
my $teststr = $camelstr x 15;
$prog =~ tr/!-~/#/;
$prog eq $teststr or print "not ";
print "ok 6\n";

# --------------------------------------------------

unlink $tmpf;
