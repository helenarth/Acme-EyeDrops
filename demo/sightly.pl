#!/usr/bin/perl
# sightly.pl.
 
use strict;
use Getopt::Std ();
use Acme::EyeDrops qw(sightly);

sub usage
{
   print STDERR <<'EOM';
usage: sightly.pl [-s shape] [-f file|-t string]
Options:
  -s shape      Shape/s. Can specify multiple shapes separated
                by commas. Six shape files are provided in the
                same directory as EyeDrops.pm, namely:
                   camel, japh, buffy, bleach, uml, window.
                A shape is just a file with an .eye suffix,
                so you can add new shapes yourself.
                In addition, the following built-in shapes are
                provided for Linux only (/usr/games/banner):
                   banner (make banner from -c switch)
                   srcbanner (make banner from source)
  -f file       The file to be made sightly.
  -z string     Specify a string instead of a file.
  -c string     String used with -s banner above.
  -p            Print instead of eval.
  -r            Insert sightly into a regex (instead of eval).
  -g gap        Gap between successive shapes.
  -b            Binary file.
  -w width      Width.
  -l            List available shapes.
  -t            Trap die within eval with 'die $@ if $@'
  -u            Trap warnings with '$SIG{__WARN__}=sub{}'
Examples:
  sightly.pl -s camel -f myprog.pl >myprog2.pl
     This creates myprog2.pl, equivalent to the original
     myprog.pl, but prettier and shaped like a camel.
  sightly.pl -pr -s window -t "Bill Gates is a pest!\n" >bill.pl
     This creates bill.pl, a program that prints the above string.
  sightly.pl -g 5 -bps camel,japh,camel -f some_binary_file >sightly
     This creates sightly, a sightly-encoded file.
     To decode it:   perl sightly > f.tmp
     To check it worked: cmp f.tmp some_binary_file
Notes:
  If no shape is specified, a single (very long) line will be output.
  If a shape, but no file, is specified, a default no-op filler will
  be used to fill the shape.
EOM
   exit 1;
}

sub list_shapes {
   my @builtin = Acme::EyeDrops::get_builtin_shapes();
   my @eye = Acme::EyeDrops::get_eye_shapes();
   print "builtin shapes  : @builtin\n";
   print ".eye file shapes: @eye\n";
}

my %optarg = (
   b => 'Binary',
   c => 'BannerString',
   f => 'SourceFile',
   g => 'Gap',
   p => 'Print',
   r => 'Regex',
   s => 'Shape',
   t => 'TrapEvalDie',
   u => 'TrapWarn',
   w => 'Width',
   z => 'SourceString'
);

usage() unless @ARGV;
my %arg = (); my %option = ();
Getopt::Std::getopts("hblprtuc:f:g:s:w:z:", \%option) or usage();
usage() if $option{h};
$option{l} and list_shapes(),exit(0);
$option{z} =~ s#\\n#\n#g if $option{z};
for my $k (keys %option) {
   next unless $option{$k};
   exists($optarg{$k}) and $arg{$optarg{$k}} = $option{$k};
}
usage() if @ARGV;
print sightly(\%arg);
