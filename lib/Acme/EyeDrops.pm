package Acme::EyeDrops;
require 5.005;
use strict;

use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(ascii_to_sightly sightly_to_ascii
                regex_print_sightly regex_eval_sightly
                clean_print_sightly clean_eval_sightly
                regex_binmode_print_sightly
                clean_binmode_print_sightly
                pour_sightly sightly);

$VERSION = '0.01';

my @C = map {"'" . chr() . "'"} 0..255;
$C[39]  = q#"'"#;

# 'a'..'o' (97..111)
my $q;
for (33..47) {
   $C[$_+64] = q#('`'|#.($q=$_==39?'"':"'").chr()."$q)";
}
# 'p'..'z' (112..122)
my $c=112;
for (43,42,41,40,47,46,45,44,35,34,33) {
   $C[$c++] = q#('['^#.($q=$_==39?'"':"'").chr()."$q)";
}
# 'A'..'O' (65..79)
for (33..47) {
   $C[$_+32] = q#('`'^#.($q=$_==39?'"':"'").chr()."$q)";
}
# 'P'..'Z' (80..90)
$c=80;
for (43,42,41,40,47,46,45,44,35,34,33) {
   $C[$c++] = q#('{'^#.($q=$_==39?'"':"'").chr()."$q)";
}
# '0'..'9' (48..57)
$c=48;
for (46,47,44,45,42,43,40,41,38,39) {
   $C[$c++] = q#('^'^('`'|#.($q=$_==39?'"':"'").chr()."$q))";
}
$C[56] = q#(':'&'=')#;
$C[57] = q#(';'&'=')#;

# 0..32, 127
$C[0]   = q#('!'^'!')#;
$C[1]   = q#('('^')')#;
$C[2]   = q#('<'^'>')#;
$C[3]   = q#('>'^'=')#;
$C[4]   = q#('>'^':')#;
$C[5]   = q#('>'^';')#;
$C[6]   = q#('+'^'-')#;
$C[7]   = q#('*'^'-')#;
$C[8]   = q!('+'^'#')!;
$C[9]   = q!('*'^'#')!;
$C[10]  = q#('!'^'+')#;      # newline
$C[11]  = q#('!'^'*')#;
$C[12]  = q#('!'^'-')#;
$C[13]  = q#('!'^',')#;
$C[14]  = q#('!'^'/')#;
$C[15]  = q#('!'^'.')#;
$C[16]  = q#('?'^'/')#;
$C[17]  = q#('<'^'-')#;
$C[18]  = q#('-'^'?')#;
$C[19]  = q#('.'^'=')#;
$C[20]  = q#('+'^'?')#;
$C[21]  = q#('*'^'?')#;
$C[22]  = q#('?'^')')#;
$C[23]  = q#('<'^'+')#;
$C[24]  = q#('%'^'=')#;
$C[25]  = q#('&'^'?')#;
$C[26]  = q#('?'^'%')#;
$C[27]  = q#('>'^'%')#;
$C[28]  = q#('&'^':')#;
$C[29]  = q#('<'^'!')#;
$C[30]  = q#('?'^'!')#;
$C[31]  = q#('%'^':')#;
$C[32]  = q#('{'^'[')#;      # space
$C[127] = q#('!'^'^')#;

# $C[10]  = join('.', q#'\\\\'#, $C[110]);   # newline \n

# Special escaped characters.
$C[92]  = q#'\\\\'.'\\\\'#;
$C[34]  = q#'\\\\'.'"'#;
$C[36]  = q#'\\\\'.'$'#;
$C[64]  = q#'\\\\'.'@'#;
$C[123] = q#'\\\\'.'{'#;
$C[125] = q#'\\\\'.'}'#;

# 128..255
for my $i (128..255) {
   $C[$i] = join('.', q#'\\\\'#,
               map($C[$_], unpack('C*', sprintf('%o', $i))));
}

sub ascii_to_sightly {
   join('.', map($C[$_], unpack('C*', $_[0])));
}

sub sightly_to_ascii {
   eval eval q#'"'.# . $_[0] . q#.'"'#;
}

sub regex_print_sightly {
   q#''=~('('.'?'.'{'.# . ascii_to_sightly('print') . q#.'"'.# .
   &ascii_to_sightly . q#.'"'.'}'.')')#;
}

sub regex_binmode_print_sightly {
   q#''=~('('.'?'.'{'.# . ascii_to_sightly('binmode(STDOUT);print')
   . q#.'"'.# .  &ascii_to_sightly . q#.'"'.'}'.')')#;
}

sub regex_eval_sightly {
   q#''=~('('.'?'.'{'.# . ascii_to_sightly('eval') . q#.'"'.# .
   &ascii_to_sightly . q#.'"'.'}'.')')#;
}

sub clean_print_sightly {
   qq#print eval '"'.\n\n\n# . &ascii_to_sightly . q#.'"'#;
}

sub clean_binmode_print_sightly {
   qq#binmode(STDOUT);print eval '"'.\n\n\n# .
   &ascii_to_sightly . q#.'"'#;
}

sub clean_eval_sightly {
   qq#eval eval '"'.\n\n\n# . &ascii_to_sightly . q#.'"'#;
}

# -----------------------------------------------------------------

# Return the largest number of tokens with combined length
# less than $slen.
sub _guess_ntok {
   my ($rtok, $sidx, $slen) = @_;
   my $eidx = $sidx + $slen - 1;
   my $tlen = 0; my $ntok = 0;
   for my $i ($sidx .. $eidx) {
      $tlen += length($rtok->[$i]);
      return $ntok if $tlen > $slen;
      ++$ntok;
   }
   return $slen;
}

# Pour $n tokens from @{$rtok} (starting at index $sidx)
# into string ${$rstr) of length $slen.
# Return 1 if successful, else 0.
sub _pour_line {
   my ($rtok, $sidx, $n, $slen, $rstr) = @_;
   my $eidx = $sidx + $n - 1;
   my $tlen = 0;
   my $idot = -1;
   my $iquote = -1;
   my $i3quote = -1;
   my $iparen = -1;
   my $idollar = -1;
   for my $i ($sidx .. $eidx) {
      $tlen += length($rtok->[$i]);
      if ($rtok->[$i] eq '.') { $idot = $i }
      if ($rtok->[$i] eq '(') { $iparen = $i }
      if ($rtok->[$i] eq '$:') { $idollar = $i }
      if (substr($rtok->[$i], 0, 1) =~ /['"]/) {
         $iquote = $i;
         $i3quote = $i if length($rtok->[$i]) == 3;
      }
   }
   if ($tlen == $slen) {
      ${$rstr} = join("", @{$rtok}[$sidx .. $eidx]);
      return 1;
   }
   # ajs: it is possible to reduce number of tokens in some
   # cases, e.g. 'a'.'b' -> 'ab'
   # Leave for now. Do later if required.
   return 0 if $tlen > $slen;

   my $diff = $slen - $tlen;
   my $i3 = int($diff/3);
   my $r3 = $diff % 3;
   if ($idot >= 0 && $r3 == 0) {
      # Multiple of 3: add .'' before a dot token.
      my $istr = ".''" x $i3;
      ${$rstr} = ($idot == $sidx) ?
         join("", $istr, @{$rtok}[$idot .. $eidx]) :
         join("", @{$rtok}[$sidx .. $idot-1], $istr,
            @{$rtok}[$idot .. $eidx]);
      return 1;
   }

   my $i2 = int($diff/2);
   my $r2 = $diff % 2;
   if ($r2 == 0 and ($iquote >= 0 or $idollar >= 0)) {
      $iquote = $idollar if $iquote < 0;
      my $istr = '(' x $i2 . $rtok->[$iquote] . ')' x $i2;
      ${$rstr} = ($iquote == $sidx) ?
         join("", $istr, @{$rtok}[$iquote+1 .. $eidx]) :
         join("", @{$rtok}[$sidx .. $iquote-1], $istr,
            @{$rtok}[$iquote+1 .. $eidx]);
      return 1;
   }

   if ($i3quote >= 0) {
      my $istr = ($diff == 1) ?
         '"\\' . substr($rtok->[$i3quote], 1, 1). '"' :
         '(' x $i2 . '"\\' . substr($rtok->[$i3quote], 1, 1)
         . '"' .  ')' x $i2;
      ${$rstr} = ($i3quote == $sidx) ?
         join("", $istr, @{$rtok}[$i3quote+1 .. $eidx]) :
         join("", @{$rtok}[$sidx .. $i3quote-1], $istr,
            @{$rtok}[$i3quote+1 .. $eidx]);
      return 1;
   }

   return 0 unless $diff == 1;
   if ($iparen >= 0) {
      my $istr = '+' . $rtok->[$iparen];
      ${$rstr} = ($iparen == $sidx) ?
         join("", $istr, @{$rtok}[$iparen+1 .. $eidx]) :
         join("", @{$rtok}[$sidx .. $iparen-1], $istr,
            @{$rtok}[$iparen+1 .. $eidx]);
      return 1;
   }
   my $nexttok = substr($rtok->[$sidx + $n], 0, 1);
   # ajs: ouch, can't test for nexttok eq '(' in case
   # next line also adds '+'
   if ($rtok->[$eidx] ne '=' and
      ($nexttok eq '"' or $nexttok eq "'")) {
   # if ($nexttok eq '"' or $nexttok eq "'") {
      ${$rstr} = join("", @{$rtok}[$sidx .. $eidx], '+');
      return 1;
   }

   return 0;
}

# Pour program $prog into shape defined by string $tlines.
sub pour_sightly {
   my ($tlines, $prog, $gap) = @_;

   my @ttlines = split(/\n/, $tlines);
   my $outstr = "";
   my @ptok = ();
   my $istart = 0;

   if ($prog) {
      my $first_bit = substr($prog, 0, 48);
      my $leading_line = $first_bit =~ /eval/;
      if ($leading_line) {
         $istart = index($first_bit, "\n\n\n");
         $istart > 0 or die "oops";
         $istart += 3;
         $outstr .= substr($first_bit, 0, $istart);
         substr($prog, 0, $istart) = "";   # chop eval lines
      } else {
         substr($first_bit, 0, 4) eq "''=~" or die "oops";
         substr($prog, 0, 4) = "";         # chop leading ''=~
         my $len1 = 0;
         my ($t) = $tlines =~ /(\S+)/;
         $t and $len1 = length($t);
         push(@ptok, $len1==3 ? "'?'" : "''", '=~');
      }
      push(@ptok,
      $prog =~ /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[().&|^~]/g);
   }

   my $iendprog = scalar(@ptok);
   my @filler = ( ';', '$:', '=',
                  q#'"'#, '|', q^'#'^,
                  ';', '$:', '=',
                  q#'?'#, '&', q#'!'#,
                  ';', '$:', '=',
                  q#'*'#, '|', q#'~'#,
                  ';', '$:', '=',
                  q#'%'#, '&', q#'$'# );
   my $nfiller = int(length($tlines)/42);  # not accurate
   $nfiller = 2 if $nfiller < 2;
   for (0 .. $nfiller) { push(@ptok, @filler) }

   my $sidx = 0;
   my $nshape = 0;
   while (1) {
      my $linenum = 0;
      for my $line (@ttlines) {
         ++$linenum;
         my @ttok = $line =~ / +|[^ ]+/g;
         for my $it (0..$#ttok) {
            my $t = $ttok[$it];
            if (substr($t, 0, 1) eq ' ') {
               $outstr .= $t;
               next;
            }
            my $tlen = length($t);
            my $plen = length($ptok[$sidx]);
            if ($plen == $tlen) {
               $outstr .= $ptok[$sidx++];
            } elsif ($plen > $tlen) {
               $outstr .= '(' x $tlen;
               my @itok = (')') x $tlen;
               splice(@ptok, $sidx+1, 0, @itok);
               $iendprog += $tlen;
            } else {
               my $n = _guess_ntok(\@ptok, $sidx, $tlen);
               my $str = "";
               while ($n > 0) {
                  if (_pour_line(\@ptok, $sidx, $n, $tlen, \$str)) {
                     # warn "line $linenum: ok, n=$n\n";
                     last;
                  } else {
                     # warn "line $linenum: failed, n=$n\n";
                     --$n;
                  }
               }
               if ($n == 0) {
                  # warn "line $linenum: failed\n";
                  # $outstr .= $ptok[$sidx++];
                  my $zlen = 0;
                  while (1) {
                     last if (substr($ptok[$sidx], 0, 1) =~ /['"]/);
                     last if $ptok[$sidx] eq '$:';
                     $outstr .= $ptok[$sidx];
                     $zlen += length($ptok[$sidx]);
                     ++$sidx;
                  }
                  die "oops ($zlen >= $tlen)" if $zlen >= $tlen;
                  my $nleft = $tlen - $zlen;
                  $outstr .= '(' x $nleft;
                  my @itok = (')') x $nleft;
                  splice(@ptok, $sidx+1, 0, @itok);
                  $iendprog += $nleft;
               } else {
                  $outstr .= $str;
                  $sidx += $n;
               }
            }
         }
         $outstr .= "\n";
      }
      ++$nshape;
      warn "$nshape shapes completed.\n";
      last if $sidx >= $iendprog;
      $outstr .= "\n" x $gap;
   }

   $outstr =~ s/\s+$/\n/;
   if ($sidx != $iendprog) {
      my $lastchar = substr($outstr, -2, 1);
      if ($lastchar eq '|' or $lastchar eq '&') {
         substr($outstr, -2, 1) = ';';
      } elsif ($lastchar ne ';' and $lastchar ne '"' and
               $lastchar ne "'") {
         # Trouble: wipe out last bit with filler
         my $idx = rindex($outstr, ';');
         if ($idx >= 0) {
            my $f = '#';
            for my $i ($idx+1 .. length($outstr) - 2) {
               my $c = substr($outstr, $i, 1);
               if ($c ne ' ' and $c ne "\n") {
                  substr($outstr, $i, 1) = $f;
                  $f = ($f eq '#') ? ';' : '#';
               }
            }
         }
      }
   }
   return $outstr;
}

# -----------------------------------------------------------------
# This section is a little bit experimental.

sub make_triangle {
   my $rarg = shift;
   my $width = $rarg->{Width};
   ++$width if $width % 2 == 0;
   $width < 9 and $width = 9;
   my $height = int($width/2) + 1;
   my $str = ""; my $ns = $height; my $nf = 1;
   for (1 .. $height) {
      $str .= ' ' x --$ns . '#' x $nf . "\n";
      $nf += 2;
   }
   return $str;
}

# Linux /usr/games/banner can be used.
# Long term, Perl CPAN Text::Banner will be enhanced
# so it can be used too.
my $banner_exe = '/usr/games/banner';
-x $banner_exe or $banner_exe = "";

sub _make_banner {
   my ($width, $src) = @_;
   $banner_exe or
      die "/usr/games/banner not available on this platform.";
   my $wflag = $width == 0 ? "" : "-w $width";
   $src =~ tr/\n/ /;
   $src =~ s/\s+/ /g;
   $src =~ s/\s+$//;
   # Alas, the following characters are not in the
   # /usr/games/banner character set:
   #    \ [ ] { } < > ^ _ | ~
   # Also must escape ' from the shell.
   $src =~ tr#\\[]{}<>^_|~'`#/()()()H-!T""#;
   my $str = "";
   my $i = 0; my $len = length($src);
   while ($i < $len) {
      my $b = substr($src, $i, 512);
      my $cmd = "$banner_exe $wflag '$b'";
      $str .= `$cmd`;
      my $rc = $? >> 8;
      $rc == 0 or die "<$cmd> failed: rc=$rc";
      $i += 512;
   }
   $str =~ s/\s+$/\n/;
   $str =~ s/ +$//sg;
   my $blen = length($str);
   warn "$len chars bannerised (bannerlen=$blen)\n";
   return $str;
}

sub make_banner {
   my $rarg = shift;
   _make_banner($rarg->{Width}, $rarg->{BannerString});
}

sub make_srcbanner {
   my $rarg = shift;
   _make_banner($rarg->{Width}, $rarg->{SourceString});
}

# -----------------------------------------------------------------

my $this_dir = __FILE__;
$this_dir =~ s#EyeDrops\.pm$##;
my $sightly_suffix = '.eye';

# The Shape attribute is a little tricky.
# First a table of "built-in" shapes is consulted.
# If not found there, an ".eye" suffix is appended and
# this file is looked for in the same directory as EyeDrops.pm.
# If not found there, a file is looked for.

my %builtin_shapes = (
   'triangle'   => \&make_triangle,
   'banner'     => \&make_banner,
   'srcbanner'  => \&make_srcbanner
);

my %default_arg = (
   Width         => 0,
   Shape         => "",
   ShapeString   => "",
   SourceFile    => "",
   SourceString  => "",
   BannerString  => "",
   Regex         => 0,
   Print         => 0,
   Binary        => 0,
   Gap           => 0
);

sub sightly {
   my ($ruarg) = @_;
   my %arg = %default_arg;
   if ($ruarg) {
      for my $k (keys %{$ruarg}) {
         exists($arg{$k}) or die "invalid parameter '$k'";
         $arg{$k} = $ruarg->{$k};
      }
   }

   if ($arg{SourceFile}) {
      open(SSS, $arg{SourceFile}) or
         die "open '$arg{SourceFile}': $!";
      binmode(SSS) if $arg{Binary};
      {
         local $/ = undef; $arg{SourceString} = <SSS>;
      }
      close(SSS);
   }

   my $shapestr = "";
   if ($arg{ShapeString}) {
      $shapestr = $arg{ShapeString};
   } elsif ($arg{Shape}) {
      my @shapes = split(/,/, $arg{Shape});
      {
         local $/ = undef;
         for my $s (@shapes) {
            if (exists($builtin_shapes{$s})) {
               $shapestr .= $builtin_shapes{$s}->(\%arg);
            } else {
               my $f = $s =~ m#[./]# ? $s :
                          $this_dir . $s . $sightly_suffix;
               open(SSS, $f) or die "open '$f': $!";
               $shapestr .= <SSS>;
               close(SSS);
            }
            $shapestr .= "\n" x $arg{Gap} if $arg{Gap};
         }
      }
   } elsif ($arg{Width}) {
      die "invalid width $arg{Width} (must be > 3)"
         if $arg{Width} < 4;
      $shapestr = '#' x $arg{Width};
   }

   my $sightlystr = "";
   if ($arg{SourceString}) {
      if ($arg{Print}) {
         if ($arg{Regex}) {
            $sightlystr = $arg{Binary} ?
               regex_binmode_print_sightly($arg{SourceString}) :
               regex_print_sightly($arg{SourceString});
         } else {
            $sightlystr = $arg{Binary} ?
               clean_binmode_print_sightly($arg{SourceString}) :
               clean_print_sightly($arg{SourceString});
         }
      } else {
         if ($arg{Regex}) {
            $sightlystr = regex_eval_sightly($arg{SourceString});
         } else {
            $sightlystr = clean_eval_sightly($arg{SourceString});
         }
      }
   }

   $shapestr or return $sightlystr;
   pour_sightly($shapestr, $sightlystr, $arg{Gap});
}

1;

__END__

=head1 NAME

Acme::EyeDrops - Visual Programming in Perl

=head1 SYNOPSIS

    use Acme::EyeDrops qw(sightly);
    
    print sightly( { Shape       => 'camel',
                     SourceFile  => 'myprog.pl' } );


=head1 DESCRIPTION

C<Acme::EyeDrops> converts a Perl program into an equivalent one,
but without all those unsightly letters and numbers.

It supports Visual Programming by allowing you to pour the generated
program into various shapes, such as UML diagrams, enabling you to
instantly understand how the program works by glancing at its new
and improved visual representation.

Like C<Acme::Smirch>, but unlike C<Acme::Bleach> and C<Acme::Buffy>,
the generated program runs without requiring that C<Acme::EyeDrops>
be installed on the target system.

=head1 EXAMPLES

Suppose you have a program, helloworld.pl, consisting of:

    print "hello world\n";

You can make this program look like a camel with:

    print sightly( { Shape       => 'camel',
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

Instead of using the API above, you may find it more convenient
to use the sightly.pl command in the demo directory:

    sightly.pl -h    (for help)
    sightly.pl -s camel -f helloworld.pl -r >new.pl
    cat new.pl
    perl new.pl      (should "print hello" world as before)

Notice that the shape 'camel' is just the file 'camel.eye' in the
same directory as EyeDrops.pm, so you are free to add your own
new shapes as required.

If your boss demands a UML diagram describing the program, you
can give him this:

    print sightly( { Shape       => 'uml',
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

If it is a Windows program, you can indicate that too, by
combining shapes:

    print sightly( { Shape       => 'uml,window',
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

producing this improved visual representation:

                ''=~('('.'?'.'{'.('`'|'%').('['^'-').(
                (                                    (
                (                                    (
                (                                    (
                (                                    (
                (                                    (
                '`'))))))))))|'!').('`'|',').'"'.('['^
                                  (
                                 ( (
                                (   (
                               '+'))))
                                  )
                                  )
                .('['^')').('`'|')').('`'|'.').(('[')^
                (                                    (
                (                                    (
 '/'))))).('{'^'[').'\\'.('"').(      '`'|'(').('`'|'%').('`'|"\,").(
 (                             (      (                             (
 (                             (      (                             (
 (                             (      (                             (
 (                             (      (                             (
 (                             (      (                             (
 '`'))))))))))))))))))))|"\,").(      '`'|'/').('{'^'[').('['^"\,").(


 '`'|'/').('['^')').('`'|',').('`'|'$').('\\').
 '\\'.('`'|'.').'\\'.'"'.';'.('!'^'+').'"'.'}'.
 ')');$:='"'|'#';$:='?'&'!';$:='*'|'~';$:="\%"&
 '$';                  $:                  ='"'
 |'#'                  ;(                  $:)=
 '?'&                  ((                  '!')
 );$:                  =(                  '*')
 |'~'                  ;(                  $:)=
 '%'&                  ((                  '$')
 );$:                  =(                  '"')
 |'#'                  ;(                  $:)=
 '?'&                  ((                  '!')
 );$:                  =(                  '*')
 |'~'                  ;(                  $:)=
 '%'&'$';$:='"'|'#';$:='?'&'!';$:='*'|('~');$:=
 '%'&                  ((                  '$')
 );$:                  =(                  '"')
 |'#'                  ;(                  $:)=
 '?'&                  ((                  '!')
 );$:                  =(                  '*')
 |'~'                  ;(                  $:)=
 '%'&                  ((                  '$')
 );$:                  =(                  '"')
 |'#'                  ;(                  $:)=
 '?'&                  ((                  '!')
 );$:                  =(                  '*')
 |'~';$:='%'&'$';$:='"'|'#';$:='?'&'!';$:="\*"|
 '~';$:='%'&'$';$:='"'|'#';$:='?'&'!';$:=('*')|
 '~';$:='%'&'$';$:='"'|'#';$:='?'&'!';$:=('*');

This is a Visual Programming breakthrough in that you can tell
that it is a Windows program and see its UML structure too,
just by glancing at the code.

For Linux-only, you can use its /usr/games/banner command
like this:

    print sightly( { Shape       => 'srcbanner',
                     Width       => 70,
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

The generated program, shown below, is easier to understand than
the original because its characters are bigger and easier to read:

 ''                                        =~ 
 +(                                        (( 
 '(')).'?'.'{'.('`'|'%').('['^'-').('`'|'!'). 
 ('`'|',').'"'.('['^'+').('['^')').('`'|')'). 
 ('`'|'.').('['^'/').('{'^'[').'\\'.'"'.('`'| 
 '(').('`'|'%').('`'|',').('`'|',').('`'|'/') 
                    .+(                (( 
                  '{'                    )) 
                 ^((                      '['
                 ))                       ).(
                '['                       ^(( 
                ',')                      )). 
                 ('`'                   |'/')
                 .(('[')^           (')')).( 
                   '`'|',').('`'|'$').'\\'.
                    '\\'.('`'|"\.").'\\'. 
                       '"'.';'.('!'^'+'
                                     
                ).+                        (( 
                '"'                        )) 
                .'}'.')');$:='"'|'#';$:="\?"& 
                '!';$:='*'|'~';$:='%'&'$';$:= 
                '"'|'#';$:='?'&'!';$:='*'|'~' 
                ;$:='%'&'$';$:='"'|'#';$:='?' 
                &((                   '!'
                                       )); 
                                        $:= 
                                        '*'| 
                                        "\~";
                                    $:=('%')& 
                                   '$';$:='"' 
                                   |('#');$:=
                                   '?'&"\!"; 
                                     ($:) 

                =((                        (( 
                '*'                        ))         ))|
                '~';$:='%'&'$';$:='"'|'#';$:=       ('?')& 
                '!';$:='*'|'~';$:='%'&'$';$:=      '"'|'#';
                $:='?'&'!';$:='*'|'~';$:='%'&       '$';$: 
                ='"'|'#';$:='?'&'!';$:=('*')|         '~'
                ;$:

                =((                        (( 
                '%'                        )) 
                ))&'$';$:='"'|'#';$:='?'&'!'; 
                $:='*'|'~';$:='%'&'$';$:='"'| 
                '#';$:='?'&'!';$:='*'|'~';$:= 
                '%'&'$';$:='"'|'#';$:='?'&'!' 
                ;$:                     =( 
                                         (( 
                                         '*')
                                         ))|+
                                         '~'; 
                $:=                     "\%"& 
                '$';$:='"'|'#';$:='?'&'!';$:= 
                '*'|'~';$:='%'&'$';$:='"'|'#'
                ;$:='?'&'!';$:='*'|"\~";$:= 
                '%'&'$';$:='"'|'#';$:='?'
                &((
                   
                                           (( 
                                           (( 
                      '!'))))));$:='*'|'~';$:=('%')&
                   '$';$:='"'|'#';$:='?'&'!';$:='*'|
                 '~';$:='%'&'$';$:='"'|'#';$:=('?')&
                '!';$:='*'|'~';$:='%'&'$';$:='"'|'#'
                ;($:)=                     (( 
                '?'))                      &+ 
                 '!' 
                 ;$: 
                   =( 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 
                                                     '*')|
                                                    '~';$:= 
                                                   '%'&"\$";$:=
                                                   '"'|'#' 
                                                    ;($:)
                                                         
                =((                                            ((
                '?'                                            ))
                ))&'!';$:='*'|'~';$:='%'&'$';$:='"'|'#';$:=('?')&
                '!';$:='*'|'~';$:='%'&'$';$:='"'|'#';$:='?'&"\!";
                $:='*'|'~';$:='%'&'$';$:='"'|'#';$:='?'&('!');$:=
                '*'|'~';$:='%'&'$';$:='"'|'#';$:='?'&'!';$:="\*"|
                '~'                     ;( 
                                         $: 
                                         )=((
                                         '%')
                                         )&(( 
                '$'                     ));$: 
                ='"'|'#';$:='?'&'!';$:=('*')| 
                '~';$:='%'&'$';$:='"'|'#';$:=
                '?'&'!';$:='*'|'~';$:="\%"& 
                '$';$:='"'|'#';$:='?'&'!'
                ;$:
                   
                          ='*'|'~'; 
                       $:='%'&"\$";$:= 
                     '"'|'#';$:='?'&'!'; 
                   $:='*'|'~';$:='%'&"\$"; 
                  $:='"'|     ((     '#')); 
                 ($:)         =(        '?') 
                 &((          ((          '!'
                )))           );           $: 
                =((           ((           (( 
                '*'           ))           )) 
                 ))           |+          '~'
                 ;(           $:        )=(( 
                  ((          ((     '%'))) 
                   )))        &'$';$:='"'| 
                     ((       "\#"));$:= 
                              '?'&'!'; 
                                    
                $:=                                            ((
                '*'                                            ))
                |'~';$:='%'&'$';$:='"'|'#';$:='?'&'!';$:='*'|'~';
                $:='%'&'$';$:='"'|'#';$:='?'&'!';$:='*'|('~');$:=
                '%'&'$';$:='"'|'#';$:='?'&'!';$:='*'|'~';$:="\%"&
                '$';$:='"'|'#';$:='?'&'!';$:='*'|'~';$:='%'&"\$";
                $:=

                '"'                                            |+
                '#'                                            ;(
                $:)='?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|"\#";$:=
                '?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|'#';$:="\?"&
                '!';$:='*'|'~';$:='%'&'$';$:='"'|'#';$:='?'&"\!";
                $:='*'|'~';$:='%'&'$';$:='"'|'#';$:='?'&('!');$:=
                '*'

                          |"\~";$:= 
                       '%'&'$';$:='"'| 
                     '#';$:='?'&"\!";$:= 
                   '*'|'~';$:='%'&"\$";$:= 
                  '"'|'#'            ;($:)= 
                 '?'&                   '!'; 
                 $:=                      '*'
                |((                        (( 
                '~'                        )) 
                ));                        $: 
                =((                       '%' 
                 ))&                     '$';
                 ($:)=                 "\""| 
                   '#';$:='?'&'!';$:=('*')|
                    '~';$:='%'&'$';$:='"' 
                      |'#';$:='?'&"\!"; 
                          $:=('*')| 
  
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 
 
 
 
                                           (( 
                                           (( 
                                        '~')) 
                                   ));$:='%'& 
                                '$';$:=('"')| 
                            '#';$:='?'&'!';$: 
                        ='*'|'~';$:="\%"&  (( 
                    '$'));$:='"'|'#';
                $:='?'&'!';$:='*'
                  |'~';$:="\%"&
                      '$';$: 
                         =('"')| 
                      '#';$:='?'&'!';
                 $:='*'|'~';$:='%' 
                  &'$';$:="\""|
                      '#';$: 
                          ="\?"& 
                              '!';$:=
                                '*'|'~'    ;( 
                                    $:)="\%"& 
                                        "\$"; 
                                           $: 
                                           =( 
                          '"')|'#'; 
                       $:='?'&"\!";$:= 
                     '*'|'~';$:='%'&'$'; 
                   $:='"'|'#';$:='?'&"\!"; 
                  $:='*'|            '~';$: 
                 ='%'                   &'$' 
                 ;$:                      =((
                '"'                        )) 
                |((                        (( 
                '#'                        )) 
                ));                       $:= 
                 '?'                     &'!'
                 ;($:)                 ='*'| 
                   '~';$:='%'&'$';$:=('"')|
                    '#';$:='?'&'!';$:='*' 
                      |'~';$:='%'&"\$"; 
                          $:=('"')| 
                '#'                        ;( 
                $:)                        =( 
                '?')&'!';$:='*'|'~';$:=('%')& 
                '$';$:='"'|'#';$:='?'&'!';$:= 
                '*'|'~';$:='%'&'$';$:='"'|'#' 
                ;$:='?'&'!';$:='*'|'~';$:='%' 
                &((                   '$'
                                       )); 
                                        $:= 
                                        '"'| 
                                        "\#";
                                    $:=('?')& 
                                   '!';$:='*' 
                                   |('~');$:=
                                   '%'&"\$"; 
                                     ($:) 

                =((                                            ((
                '"'                                            ))
                ))|'#';$:='?'&'!';$:='*'|'~';$:='%'&'$';$:=('"')|
                '#';$:='?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|"\#";
                $:='?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|('#');$:=
                '?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|'#';$:="\?"&
                '!'

                         ;$:='*'|'~';
                       $:='%'&('$');$:=
                    '"'|'#';$:='?'&'!';$: 
                   ='*'|'~';$:='%'&"\$";$:=
                 '"'|'#';           $:="\?"& 
                 '!';                   ($:)=
                '*'|                      '~' 
                ;$:                       =(( 
                 ((                       '%'
                 )))                      )&+
                  '$'                    ;( 
                    $:)                =(                      ((
                '"')))|'#';$:='?'&'!';$:='*'|'~';$:='%'&('$');$:=
                '"'|'#';$:='?'&'!';$:='*'|'~';$:='%'&'$';$:="\""|
                '#';$:='?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|"\#";
                $:='?'&'!';$:='*'|'~';$:='%'&'$';$:='"'|('#');$:=
                '?'
                &((

                '!') 
                  );$:= 
                     "\*"| 
                        '~';$:
                            ='%'&
                               "\$"; 
                                  ($:)= 
                                     "\""| 
                                       "\#"; 
                                          ($:)= 
                                             "\?"& 
                                                '!';$:
                                                   ="\*"|
                                                       "\~";
                                                          ($:)= 
                                                             '%'&
                                                                 
                '$'                        ;( 
                $:)                        =( 
                '"')|'#';$:='?'&'!';$:=('*')| 
                '~';$:='%'&'$';$:='"'|'#';$:= 
                '?'&'!';$:='*'|'~';$:='%'&'$' 
                ;$:='"'|'#';$:='?'&'!';$:='*' 
                |((                     (( 
                                         (( 
                                         '~')
                                         ))))
                                         );$: 
                =((                     '%')) 
                &'$';$:='"'|'#';$:='?'&'!';$: 
                ='*'|'~';$:='%'&'$';$:=('"')|
                '#';$:='?'&'!';$:='*'|"\~"; 
                $:='%'&'$';$:='"'|'#';$:=
                '?'
                   
                                                     &'!';
                                                    $:='*'| 
                                                   '~';$:="\%"&
                                                   '$';$:= 
                                                    "\""|

                                                         
                   '#'                  ;$:
                 ="\?"&                "\!"; 
                $:="\*"|              '~';$:= 
            '%'&"\$";$:=              '"'|'#' 
               ;$:='?'&                "\!";


The shapes 'bleach' and 'buffy' are also provided to aid folks
migrating from Acme::Bleach and Acme::Buffy.

Let's get more ambitious and create a big JAPH.

    my $src = <<'PROG';
    open 0;
    $/ = undef;
    $x = <0>;
    close 0;
    $x =~ tr/!-~/#/;
    print $x;
    PROG
    print sightly({ Shape         => 'japh',
                    SourceString  => $src,
                    Regex         => 1 } );

This works. However, if we were to change:

    $x =~ tr/!-~/#/;

to:

    $x =~ s/\S/#/g;

the generated program would malfunction in strange ways because
it is running inside a regular expression and Perl's regex engine
is not reentrant. In this case, we must resort to:

    print sightly({ Shape         => 'japh',
                    SourceString  => $src,
                    Regex         => 0 } );

which runs the generated sightly program via eval instead.

EyeDrops can also convert plain text:

    print sightly({ Shape         => 'window',
                    SourceString  => "Bill Gates is a pest!\n",
                    Regex         => 1,
                    Print         => 1 } );

In this example, the generated program will print the SourceString
above.

But wait, there's more. You can encode binary files too.

    print sightly({ Shape       => 'camel,japh,camel',
                    SourceFile  => 'some_binary_file',
                    Binary      => 1,
                    Print       => 1,
                    Gap         => 5 } );

This is prettier than uuencode/uudecode.
Here is how you do it with sightly.pl:

    sightly.pl -g5 -bps camel,japh,camel -f some_binary_file >fred

To decode:

    perl fred >f.tmp

To verify it worked:

    cmp f.tmp some_binary_file

The sightly-encoding engine is implemented in the functions
C<ascii_to_sightly> and C<sightly_to_ascii>.

=head1 BUGS

A really diabolical shape with lots of single character lines
will defeat the shape-pouring algorithm.

In the general case, all unsightly alphanumerics are not
eliminated because of the need for a leading eval.

=head1 AUTHOR

Andrew Savige <andrew.savige@ir.com>

=head1 SEE ALSO

L<Acme::Bleach>
L<Acme::Smirch>
L<Acme::Buffy>

=head1 CREDITS

I blame Japhy and Ronald J Kimball and others on the fwp
mailing list for exposing the ''=~ trick and Jas Nagra
for explaining his Acme::Smirch module.

=head1 COPYRIGHT

Copyright (c) 2001 Andrew Savige. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
