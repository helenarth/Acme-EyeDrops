use strict;
use Acme::EyeDrops qw(sightly);

# Test program for module bug raised by Mark Puttman.

print "1..4\n";

my $module_str = <<'GROK';
package MyEye;
use strict;

sub new
{
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self={};
     $self->{name}=shift;
  bless $self,$class;
  return $self;
}

sub printName
{
  my $self=shift;
  print "My Name is $self->{name}\n";
}

1;
GROK

my $main_str = <<'GROK';
use MyEye;

my $obj=MyEye->new("mark");
$obj->printName();
GROK

sub BuildFile {
   my ($fname, $data) = @_;
   open(FF, '>'.$fname) or die "error: open '$fname'";
   print FF $data;
   close(FF);
}

sub get_shape_str {
   my $sfile = "lib/Acme/$_[0].eye";
   local *TT;
   open(TT, $sfile) or die "open '$sfile': $!";
   local $/ = undef;
   my $str = <TT>;
   close(TT);
   return $str;
}

BuildFile('t/eye.tmp', $module_str);
BuildFile('t/myeye.pl', $main_str);

my $camelstr = get_shape_str('camel');
my $japhstr = get_shape_str('japh');
my $tmpf = 'bill.tmp';

# JAPH  MyEye.pm -----------------------------------

my $prog = sightly({ Shape         => 'japh',
                     SourceFile    => 't/eye.tmp',
                     Regex         => 1 } );
unlink('t/eye.tmp');
chdir('t') or die "chdir: $!";
open(TT, '>MyEye.pm') or die "open MyEye.pm: $!";
print TT $prog;
close(TT);
$prog =~ tr/!-~/#/;
$prog eq $japhstr or print "not ";
print "ok 1\n";
chdir('..') or die "chdir: $!";

# Camel myeye.pl -----------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceFile    => 't/myeye.pl',
                  Regex         => 1 } );
chdir('t') or die "chdir: $!";
open(TT, '>'.$tmpf) or die "open >$tmpf : $!";
print TT $prog;
close(TT);
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
print "ok 2\n";
$outstr eq "My Name is mark\n" or print "not ";
print "ok 3\n";
$prog =~ tr/!-~/#/;
$prog eq $camelstr or print "not ";
print "ok 4\n";
unlink $tmpf;

# --------------------------------------------------

chdir('..') or die "chdir: $!";
