use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# Test program for module bug raised by Mark Puttman.

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d; close(F);
}

# --------------------------------------------------

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

build_file('t/eye.tmp', $module_str);
build_file('t/myeye.pl', $main_str);

my $camelstr = get_eye_string('camel');
my $japhstr = get_eye_string('japh');
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

exit 0;
