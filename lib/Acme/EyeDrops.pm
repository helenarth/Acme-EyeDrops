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
                get_builtin_shapes get_eye_shapes
                border_shape invert_shape
                reflect_shape rotate_shape
                pour_sightly sightly);

$VERSION = '1.03';

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
      # map($C[$_], unpack('C*', sprintf('%o', $i))));
      $C[120], map($C[$_], unpack('C*', sprintf('%x', $i))));
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
   my ($rtok, $sidx, $slen, $rexact) = @_;
   my $eidx = $sidx + $slen - 1;
   my $tlen = 0; my $ntok = 0; ${$rexact} = 0;
   for my $i ($sidx .. $eidx) {
      $tlen += length($rtok->[$i]);
      if ($tlen == $slen) {
         ${$rexact} = 1;
         return $ntok+1;
      } elsif ($tlen > $slen) {
         return $ntok;
      }
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
      if (substr($rtok->[$i], 0, 1) eq '$') { $idollar = $i }
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
   # my $r2 = $diff % 2;
   my $r2 = $diff & 1;
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
   my ($tlines, $prog, $gap, $rfillvar) = @_;

   $tlines =~ s/ +$//mg;
   my @tnlines = ();
   for my $line (split(/\n/, $tlines)) {
      if ($line =~ /^\s*$/) {
         push(@tnlines, undef); next;
      }
      my @oneline = ();
      my @ttok = $line =~ / +|[^ ]+/g;
      push(@oneline, 0) if substr($ttok[0], 0, 1) ne ' ';
      push(@oneline, map { length } @ttok);
      push(@tnlines, [ @oneline ] );
   }

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
   # Beware with these filler values.
   # See "Trouble: wipe out last bit" comment below.
   # Avoid $; $" and ';'.
   # An END block might cause trouble because
   # it is executed after this filler code.
   # For more variety may try ($/ $\ $,) but for now stick
   # just to 'format' variables ($: $~ $^) since a format
   # in an END block is considered unlikely.
   # Oops, setting $^ or $~ (but not $:) to weird values resets $@ !!
   # For example: $~='?'&'!';
   # (this looks like a Perl bug to me).
   # Safest to stick with letters and numbers.
   my @filleqto = ( [ q#'.'#, '^', q^'~'^ ],
                    [ q#'@'#, '|', q^'('^ ],
                    [ q#')'#, '^', q^'['^ ],
                    [ q#'`'#, '|', q^'.'^ ],
                    [ q#'('#, '^', q^'}'^ ],
                    [ q#'`'#, '|', q^'!'^ ],

                    [ q#')'#, '^', q^'}'^ ],
                    [ q#'*'#, '|', q^'`'^ ],
                    [ q#'+'#, '^', q^'_'^ ],
                    [ q#'&'#, '|', q^'@'^ ],
                    [ q#'['#, '&', q^'~'^ ],
                    [ q#','#, '^', q^'|'^ ],
                    # [ q#'@'#, '|', q^'+'^ ],
                    # [ q#':'#, '&', q^'='^ ],
                    # [ q#'}'#, '&', q^'{'^ ],
                    # [ q#']'#, '&', q^'['^ ],
                  );
   # for my $c (@filleqto) {
   # my $z=join("",@{$c});my $x=eval $z;print "z=$z eqto=$x:\n" }
   scalar(@{$rfillvar}) > scalar(@filleqto) and
      die "oops: too many rfillvar";
   my $modo = scalar(@filleqto) % scalar(@{$rfillvar});
   splice(@filleqto, -$modo) if $modo;
   my @filler = ();
   my $vi = 0;
   for my $e (@filleqto) {
      push(@filler, ';', $rfillvar->[$vi], '=', @{$e});
      ++$vi;
      $vi = 0 if $vi > $#{$rfillvar};
   }
   my $filllen = 0;
   for my $t (@filler) { $filllen += length($t) }
   my $nfiller = int(length($tlines)/$filllen) + 1;
   for (0 .. $nfiller) { push(@ptok, @filler) }

   my $sidx = 0;
   my $nshape = 0;
   my $exactfit;
   while (1) {
      my $linenum = 0;
      for my $rline (@tnlines) {
         ++$linenum;
         unless ($rline) {
            $outstr .= "\n"; next;
         }
         for my $it (0 .. $#{$rline}) {
            # if ($it % 2 == 0) {
            unless ($it & 1) {
               $outstr .= ' ' x $rline->[$it]; next;
            }
            my $tlen = $rline->[$it];
            my $plen = length($ptok[$sidx]);
            if ($plen == $tlen) {
               $outstr .= $ptok[$sidx++];
            } elsif ($plen > $tlen) {
               $outstr .= '(' x $tlen;
               my @itok = (')') x $tlen;
               splice(@ptok, $sidx+1, 0, @itok);
               $iendprog += $tlen;
            } else {
               my $n = _guess_ntok(\@ptok, $sidx, $tlen, \$exactfit);
               if ($exactfit) {
                  $outstr .= join("", @ptok[$sidx .. $sidx+$n-1]);
                  $sidx += $n;
               } else {
                  my $str = "";
                  while ($n > 0) {
                     if (_pour_line(\@ptok,$sidx,$n,$tlen,\$str)) {
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
                        last if substr($ptok[$sidx], 0, 1) =~ /['"]/;
                        last if substr($ptok[$sidx], 0, 1) eq '$';
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
         }
         $outstr .= "\n";
      }
      ++$nshape;
      warn "$nshape shapes completed.\n";
      last if $sidx >= $iendprog;
      $outstr .= "\n" x $gap;
   }

   # $outstr =~ s/\s+$/\n/;
   if ($sidx != $iendprog) {
      my $lastchar = substr($outstr, -2, 1);
      my $lc2 = substr($outstr, -3, 1);
      if ($lc2 ne '$' and
      ($lastchar eq '|' or $lastchar eq '^' or $lastchar eq '&')) {
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

# Put a border of $fillc around shape defined by $rarr.
sub _border {
   my ($rarr, $width, $fillc, $left, $right, $top, $bottom) = @_;
   my $lfill = $fillc x $left; my $rfill = $fillc x $right;
   for my $l (@{$rarr}) { $l = $lfill . $l . $rfill }
   my $line = $fillc x ($width + $left + $right);
   unshift(@{$rarr}, ($line) x $top);
   push(@{$rarr}, ($line) x $bottom);
}

# Put a border around a shape.
sub border_shape {
   my ($tlines, $gap_left, $gap_right, $gap_top, $gap_bottom,
       $width_left, $width_right, $width_top, $width_bottom) = @_;
   my @a = split(/\n/, $tlines);
   my $maxlen = 0;
   for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
   for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                       if length($l) < $maxlen }
   if ($gap_left or $gap_right or $gap_top or $gap_bottom) {
      _border(\@a, $maxlen, ' ',
         $gap_left, $gap_right, $gap_top, $gap_bottom);
   }
   $maxlen += $gap_left + $gap_right;
   if ($width_left or $width_right or $width_top or $width_bottom) {
      _border(\@a, $maxlen, '#',
         $width_left, $width_right, $width_top, $width_bottom);
   }
   return join("\n", @a) . "\n";
}

# Invert shape (i.e. convert '#' to space and vice-versa).
sub invert_shape {
   my ($tlines) = @_;
   my @a = split(/\n/, $tlines);
   my $maxlen = 0;
   for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
   for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                       if length($l) < $maxlen }
   my $s = join("\n", @a) . "\n";
   $s =~ tr/ #/# /;
   return $s;
}

# Reflect shape
sub reflect_shape {
   my ($tlines) = @_;
   my @a = split(/\n/, $tlines);
   my $maxlen = 0;
   for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
   for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                       if length($l) < $maxlen }
   for my $l (@a) { $l = reverse($l) }
   return join("\n", @a) . "\n";
}

# Rotate shape clockwise: 90, 180 or 270 degrees
# (other angles are left as an exercise for the reader:-)
sub rotate_shape {
   my ($tlines, $degrees) = @_;
   if ($degrees == 180) {
      my @a = reverse split(/\n/, $tlines);
      return join("\n", @a) . "\n";
   }
   if ($degrees == 90) {
      my @a = split(/\n/, $tlines);
      my $maxlen = 0;
      for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
      for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                          if length($l) < $maxlen }
      my @n = ();
      for my $i (0 .. $maxlen-1) {
         my $line = "";
         for my $l (reverse @a) { $line .= substr($l, $i, 1) }
         push(@n, $line);
      }
      return join("\n", @n) . "\n";
   }
   if ($degrees == 270) {
      my @a = split(/\n/, $tlines);
      my $maxlen = 0;
      for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
      for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                          if length($l) < $maxlen }
      my @n = ();
      my $i;
      for ($i = $maxlen-1; $i >= 0; --$i) {
         my $line = "";
         for my $l (@a) { $line .= substr($l, $i, 1) }
         push(@n, $line);
      }
      return join("\n", @n) . "\n";
   }
}

sub make_triangle {
   my $rarg = shift;
   my $width = $rarg->{Width};
   # ++$width if $width % 2 == 0;
   ++$width unless $width & 1;
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
   $str =~ s/ +$//mg;
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
   Width             => 0,
   Shape             => "",
   ShapeString       => "",
   SourceFile        => "",
   SourceString      => "",
   BannerString      => "",
   Regex             => 0,
   Print             => 0,
   Binary            => 0,
   Gap               => 0,
   Rotate            => 0,
   Reflect           => 0,
   Invert            => 0,
   Indent            => 0,
   BorderGap         => 0,
   BorderGapLeft     => 0,
   BorderGapRight    => 0,
   BorderGapTop      => 0,
   BorderGapBottom   => 0,
   BorderWidth       => 0,
   BorderWidthLeft   => 0,
   BorderWidthRight  => 0,
   BorderWidthTop    => 0,
   BorderWidthBottom => 0,
   TrapEvalDie       => 0,
   TrapWarn          => 0,
   FillerVar         => []
);

sub get_builtin_shapes {
   sort keys %builtin_shapes;
}

sub get_eye_shapes {
   my $dir = $this_dir ? $this_dir : '.';
   opendir(DD, $dir) or return ();
   my @eye = sort map { substr($_, 0, length($_)-4) }
                grep { /\.eye$/ } readdir(DD);
   closedir(DD);
   return @eye;
}

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
   if ($shapestr) {
      if ($arg{Rotate}) {
         $shapestr = rotate_shape($shapestr, $arg{Rotate});
      }
      if ($arg{Reflect}) {
         $shapestr = reflect_shape($shapestr);
      }
      if ($arg{Invert}) {
         $shapestr = invert_shape($shapestr);
      }
      if ($arg{BorderGap}       or $arg{BorderWidth}       or
          $arg{BorderGapLeft}   or $arg{BorderWidthLeft}   or
          $arg{BorderGapRight}  or $arg{BorderWidthRight}  or
          $arg{BorderGapTop}    or $arg{BorderWidthTop}    or
          $arg{BorderGapBottom} or $arg{BorderWidthBottom}) {
         my $gapleft = $arg{BorderGap};
         $gapleft = $arg{BorderGapLeft} if $arg{BorderGapLeft};
         my $gapright = $arg{BorderGap};
         $gapright = $arg{BorderGapRight} if $arg{BorderGapRight};
         my $gaptop = $arg{BorderGap};
         $gaptop = $arg{BorderGapTop} if $arg{BorderGapTop};
         my $gapbottom = $arg{BorderGap};
         $gapbottom = $arg{BorderGapBottom} if $arg{BorderGapBottom};
         my $widthleft = $arg{BorderWidth};
         $widthleft = $arg{BorderWidthLeft} if $arg{BorderWidthLeft};
         my $widthright = $arg{BorderWidth};
         $widthright = $arg{BorderWidthRight} if $arg{BorderWidthRight};
         my $widthtop = $arg{BorderWidth};
         $widthtop = $arg{BorderWidthTop} if $arg{BorderWidthTop};
         my $widthbottom = $arg{BorderWidth};
         $widthbottom = $arg{BorderWidthBottom}
                           if $arg{BorderWidthBottom};
         $shapestr = border_shape($shapestr,
                      $gapleft,   $gapright,   $gaptop,   $gapbottom,
                      $widthleft, $widthright, $widthtop, $widthbottom);
      }
      if ($arg{Indent}) {
         my $s = ' ' x $arg{Indent};
         $shapestr =~ s/^/$s/mg;
      }
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

   my @fill = ();
   if (@{$arg{FillerVar}}) {
      @fill = @{$arg{FillerVar}};
   } else {
      # Non-rigourous check for module (package) or END block.
      @fill = ( '$:', '$~', '$^' , '$/', '$_', '$,', '$\\' );
      my $danger = 0;
      $danger = 1 if $arg{SourceString} =~ /^\s*END\b/m;
      $danger = 1 if $arg{SourceString} =~ /^\s*package\b/m;
      $danger and @fill = ( '$:', '$~', '$^' );
   }

   return pour_sightly($shapestr, $sightlystr, $arg{Gap}, \@fill)
      unless ($arg{TrapEvalDie} or $arg{TrapWarn});

   if ($arg{TrapEvalDie}) {
      if ($arg{TrapWarn}) {
         return 'local $SIG{__WARN__}=sub{};' .
            pour_sightly($shapestr, $sightlystr, $arg{Gap}, \@fill) .
            "\n\n\n;die \$\@ if \$\@\n";
      } else {
         return pour_sightly($shapestr, $sightlystr, $arg{Gap},
                \@fill) .  "\n\n\n;die \$\@ if \$\@\n";
      }
   } else {
      return 'local $SIG{__WARN__}=sub{};' .
         pour_sightly($shapestr, $sightlystr, $arg{Gap}, \@fill);
   }
}

1;

__END__

=head1 NAME

Acme::EyeDrops - Visual Programming in Perl

=head1 SYNOPSIS

    use Acme::EyeDrops qw(sightly);

    print sightly( { Shape       => 'camel',
                     SourceFile  => 'eyesore.pl' } );


=head1 DESCRIPTION

C<Acme::EyeDrops> converts a Perl program into an equivalent one,
but without all those unsightly letters and numbers.

In a Visual Programming breakthrough, EyeDrops allows you to pour
the generated program into various shapes, such as UML diagrams,
enabling you to instantly understand how the program works just
by glancing at its new and improved visual representation.

Like C<Acme::Smirch>, but unlike C<Acme::Bleach> and C<Acme::Buffy>,
the generated program runs without requiring that C<Acme::EyeDrops>
be installed on the target system.

=head1 EXAMPLES

Suppose you have a program, F<helloworld.pl>, consisting of:

    print "hello world\n";

You can make this program look like a camel with:

    print sightly( { Shape       => 'camel',
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

Instead of using the API above, you may find it more convenient
to use the F<sightly.pl> command in the F<demo> directory:

    sightly.pl -h           (for help)
    sightly.pl -s camel -f helloworld.pl -r >new.pl
    cat new.pl
    perl new.pl             (should print "hello world" as before)

Notice that the shape C<'camel'> is just the file F<camel.eye> in
the same directory as F<EyeDrops.pm>, so you are free to add your
own new shapes as required.

If your boss demands a UML diagram describing the program, you
can give him this:

    print sightly( { Shape       => 'uml',
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

If it is a Windows program, you can indicate that too, by
combining shapes:

    print sightly( { Shape       => 'uml,window',
                     Gap         => 1,
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

 '`'|'/').('['^')').('`'|',').('`'|'$').'\\'.'\\'
 .('`'|'.').'\\'.'"'.';'.('!'^'+').'"'.'}'."\)");
 $:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|"\.";$_=
 "\("^                  ((                  '}'))
 ;($,)                  =(                  '`')|
 "\!";                  $\                  =')'^
 "\}";                  $:                  ='.'^
 "\~";                  $~                  ='@'|
 "\(";                  $^                  =')'^
 "\[";                  $/                  ='`'|
 "\.";                  $_                  ='('^
 "\}";                  $,                  ='`'|
 "\!";                  $\                  =')'^
 "\}";                  $:                  ='.'^
 '~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';
 ($,)=                  ((                  '`'))
 |'!';                  $\                  =')'^
 "\}";                  $:                  ='.'^
 "\~";                  $~                  ='@'|
 "\(";                  $^                  =')'^
 "\[";                  $/                  ='`'|
 "\.";                  $_                  ='('^
 "\}";                  $,                  ='`'|
 "\!";                  $\                  =')'^
 "\}";                  $:                  ='.'^
 "\~";                  $~                  ='@'|
 '(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';
 $\=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^"\[";$/=
 '`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}';$:='.';

This is a Visual Programming breakthrough in that you can tell
that it is a Windows program and see its UML structure too,
just by glancing at the code.

You can convert Perl 5 programs to Perl 6 simply by arranging
for them to impersonate the Perl 6 maestros,
I<Larry Wall> and I<Damian Conway>:

    print sightly( { Shape       => 'larry,damian',
                     Gap         => 2,
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

producing:

                          ''=~('('.'?'.'{'
                       .('`'|'%').('['^"\-").(
                  '`'|'!').('`'|',').'"'.(('[')^
                '+').                         ('['
              ^')'                              ).(
            '`'|                                  ')'
          ).+(                                   (  '`'
         )|((                                    (   '.'
        ))))                                  .(  (    '['
      )^((                                   (     (    '/'
    )))                                    ))       .(   '{'
   ^((                                   ((           (   '['
  )))                                ))).              (   (((
 (((                             '\\'                   )   )))
 )))                         .'"'                        .   (((
 '`'                ))|'(').(                            (   '`'
 )|+              ((                                     (    ((
 '%'             ))                                       )   ))
 ).(            (                                         (   ((
 '`'            )                                          )))|+
 ','           )                                              .(
 '`'           |          ',').('`'|'/').('{'^'[').('['^(',')).(
 '`'           |'/').("\["^    "\)").(    (    (   "\`"))|     (
 ','           )          ) .+(  '`'  |+  (    ( ((  '$'  )))  )
 ).+           (          ( '\\')).'\\'.  (    ( '`')|('.')).  (
 (((           (          (               (    (               (
 ((   (((     (           (               (    ((              (
 ((   (  '\\')             )              )     ))             )
 ))   )                     )             )     ) )            )
 ))   )  )))                 ))).'"'.';'.(       ( '!')^('+')).
 ((    (                              (          (          (
  (     (                            (          (           (
   (     (                            ( '"'    )            )
    )      )))                              ))             )
     )       )                  ))).'}'.')');$:="\."^      (
      (      (                '~')));$~='@'|'(';$^=')'     ^
       (     (               '['));$/='`'|'.';$_=('(')^   (
        (   (                '}'))  );$,='`'|"\!";  ($\)  =
         ( (                 ')')  )              ^  '}' ;
          $:                 =((   '.'))^'~';$~='@'   |((
           (                                            (
           (                                           (
           (                                          (
          (       (                                  (
          (        (                                (
          (          (                             (
          (            (                          (
         (               (                       (   (
         (                 (                    (     (
        (                    '('              ))       )
       )                          )))))))))))            )


                      )))))))))))));(
                    $^)=')'^'[';$/="\`"|
                  '.';$_='('^'}';$,='`'|'!'
                ;$\=                     ')'^
              '}';                         ($:)
            ='.'                             ^'~'
           ;$~=                                 '@'|
          '(';                                   ($^)
         =')'                                     ^'['
        ;$/=                                       '`'|
       '.';                                         $_=
       '('^                                         '}';
      ($,)                                    ="\`"| '!';
      ($\)                                =')'     ^  '}'
      ;$:    =((                  ('.')))^          (  '~'
     );(     (  $~))           =((                  (  '@'
    )))      |      '(';$^=')'^                     (  '['
    );(      (                                      (  $/)
    ))=      (                                      (  '`'
    ))|      (                                       ( '.'
    ));     (                                        ( $_)
     )=(    (                                        ( '('
     ))     )                                        ^ '}'
    ; $,    =                                        ( ((
    (  ((  (                                         ( ((
    (   '`')       )))))))))              )|'!';     $\=
    (    ')'    )^+         '}'        ;$:      =((  '.'
    ) )^  ((        '~'));$~             =('@')|      ((
    ( (   ((      ((  '(')  ))    )    )) ));(  $^    )
    = (  ')'       )^"\[";$/=     (    '`')|'.';$_    =
    (  (( ((                      (                  (
     (    ((                      (                 ((
     (    '('                     )                 ))
      )   )))                     )                )))
       )))^'}'                    ;                $,=
         "\`"|              (     (    (          '!'
         )));(              (     (    (          $\)
         )))=((             ')'))^'}';$:         ='.'
         ^"\~";                                  ($~)
         =('@')|         '(';$^=')'^"\[";$/=    '`'|
          "\.";$_=    '('^'}';$,='`'|('!');$\= ')'^
           "\}";$:=  ((                     "\."))^
           '~';$~="\@"|  '(';$^=')'^'[';$/=  ('`')|
            '.';$_='('      ^'}';$,="\`"|    "\!";
             $\=')'^'}'                    ;($:)=
              '.'^('~');$~=            '@'|"\(";
               $^=')'^'[';$/='`'|'.';$_='('^'}'
               ;$,='`'|'!';$\=')'^'}';$:=('.')^
                '~';$~='@'|'(';$^=')'^('[');$/=
                 '`'|'.';$_='('^'}';$,='`'|'!';
                  $\=')'^'}';$:='.'^'~';$~='@'
                    |'(';$^=')'^'[';$/=('`')|
                     '.';$_='('^'}';$,="\`"|
                       '!';$\=')'^('}');$:=
                         '.'^'~';$~=('@')|
                            '(';$^=')';

If you sincerely idolize Larry, you might put a picture frame
around him:

    print sightly( { Shape       => 'larry2',
                     BorderGap   => 3,
                     BorderWidth => 2,
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

where the shape C<larry2> is a caricature contributed by Ryan King:

 ''=~('('.'?'.'{'.('`'|'%').('['^'-').('`'|'!').("\`"|
 ',').'"'.('['^'+').('['^')').('`'|')').('`'|'.').('['
 ^+                                                 ((
 ((                                                 ((
 ((                                                 ((
 ((                 '/')))))))))))                  ))
 .(             '{'^'[').'\\'.'"'.('`'              |+
 ((            '('))).('`'|'%').('`'|','            ).
 +(          '`'|(',')).( '`'|'/'). ('{'^           ((
 ((         '['))))).('['  ^',').(  ((  '`'         ))
 |+        '/' ).('['^')') .("\`"|  (    ','        ))
 .(       '`' |"\$").'\\'.  '\\'.  (      '`'       |+
 ((       '.' ))).('\\').   '"'.  (        ((       ((
 ((      ';') )))))).''.   ('!'             ^       ((
 ((     '+'))) )). '"'    . (             ((        ((
 ((    '}')))))) )      . (    (    (     ((        ((
 ((    ')')))))) ))));    $:='.'^'~';$~=('@')|      ((
 ((    '(')))); $^  ="\)"^      (( ((    (  ((      ((
 ((     '[')))))     )))         ) )     )   ;(     $/
 )=    '`'|'.';       $_       = ( ( (    (  ((     ((
 ((     '('))))       ))         ) )      )  )^     ((
 ((      '}')))        );       $,  =(     '`'      )|
 ((       "\!"));  (    $\)=')'^     '}'; $:        =(
 ((        '.')))^ (        '~'); ($~)= ( ((        ((
 ((         '@'))))))      )|"\(";  $^=')'^'['      ;(
 $/           )="\`"|   '.';$_='('   ^'}';$,='`'    |+
 ((            '!')) ; $\=(')')^        (  "\}");   $:
 =(                (  '.'))      ^'~'     ;  ($~)   =(
 ((              ( (   '@'               )    )))   )|
 ((           '(' )    );  (            (     $^    ))
 =(         ((  (       (    "\)")))))^       (     ((
 ((      '['     ))           )                     ))
 ;(     (         $/           ))                   =(
 ((   (             ((        (   (                 ((
 ((                   '`')))))     )                ))
 ))                                                 ))
 |+                                                 ((
 ((                                                 ((
 '.'))))));$_='('^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~'
 ;$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,="\`";

For Linux-only, you can apply its F</usr/games/banner> command
to the program's source text:

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
                .'}'.')');$:='.'^'~';$~="\@"|
                '(';$^=')'^'[';$/='`'|'.';$_=
                '('^'}';$,='`'|'!';$\=')'^'}'
                ;$:='.'^'~';$~='@'|'(';$^=')'
                ^((                   '['
                                       ));
                                        $/=
                                        '`'|
                                        "\.";
                                    $_=('(')^
                                   '}';$,='`'
                                   |('!');$\=
                                   ')'^"\}";
                                     ($:)

                =((                        ((
                '.'                        ))         ))^
                '~';$~='@'|'(';$^=')'^'[';$/=       ('`')|
                '.';$_='('^'}';$,='`'|'!';$\=      ')'^'}';
                $:='.'^'~';$~='@'|'(';$^=')'^       '[';$/
                ='`'|'.';$_='('^'}';$,=('`')|         '!'
                ;$\

                =((                        ((
                ')'                        ))
                ))^'}';$:='.'^'~';$~='@'|'(';
                $^=')'^'[';$/='`'|'.';$_='('^
                '}';$,='`'|'!';$\=')'^'}';$:=
                '.'^'~';$~='@'|'(';$^=')'^'['
                ;$/                     =(
                                         ((
                                         '`')
                                         ))|+
                                         '.';
                $_=                     "\("^
                '}';$,='`'|'!';$\=')'^'}';$:=
                '.'^'~';$~='@'|'(';$^=')'^'['
                ;$/='`'|'.';$_='('^"\}";$,=
                '`'|'!';$\=')'^'}';$:='.'
                ^((

                                           ((
                                           ((
                      '~'))))));$~='@'|'(';$^=(')')^
                   '[';$/='`'|'.';$_='('^'}';$,='`'|
                 '!';$\=')'^'}';$:='.'^'~';$~=('@')|
                '(';$^=')'^'[';$/='`'|'.';$_='('^'}'
                ;($,)=                     ((
                '`'))                      |+
                 '!'
                 ;$\
                   =(
















                                                     ')')^
                                                    '}';$:=
                                                   '.'^"\~";$~=
                                                   '@'|'('
                                                    ;($^)

                =((                                            ((
                ')'                                            ))
                ))^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=(')')^
                '}';$:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|"\.";
                $_='('^'}';$,='`'|'!';$\=')'^'}';$:='.'^('~');$~=
                '@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,="\`"|
                '!'                     ;(
                                         $\
                                         )=((
                                         ')')
                                         )^((
                '}'                     ));$:
                ='.'^'~';$~='@'|'(';$^=(')')^
                '[';$/='`'|'.';$_='('^'}';$,=
                '`'|'!';$\=')'^'}';$:="\."^
                '~';$~='@'|'(';$^=')'^'['
                ;$/

                          ='`'|'.';
                       $_='('^"\}";$,=
                     '`'|'!';$\=')'^'}';
                   $:='.'^'~';$~='@'|"\(";
                  $^=')'^     ((     '['));
                 ($/)         =(        '`')
                 |((          ((          '.'
                )))           );           $_
                =((           ((           ((
                '('           ))           ))
                 ))           ^+          '}'
                 ;(           $,        )=((
                  ((          ((     '`')))
                   )))        |'!';$\=')'^
                     ((       "\}"));$:=
                              '.'^'~';

                $~=                                            ((
                '@'                                            ))
                |'(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';
                $\=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^('[');$/=
                '`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}';$:="\."^
                '~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^"\}";
                $,=

                '`'                                            |+
                '!'                                            ;(
                $\)=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^"\[";$/=
                '`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}';$:="\."^
                '~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^"\}";
                $,='`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|('(');$^=
                ')'

                          ^"\[";$/=
                       '`'|'.';$_='('^
                     '}';$,='`'|"\!";$\=
                   ')'^'}';$:='.'^"\~";$~=
                  '@'|'('            ;($^)=
                 ')'^                   '[';
                 $/=                      '`'
                |((                        ((
                '.'                        ))
                ));                        $_
                =((                       '('
                 ))^                     '}';
                 ($,)=                 "\`"|
                   '!';$\=')'^'}';$:=('.')^
                    '~';$~='@'|'(';$^=')'
                      ^'[';$/='`'|"\.";
                          $_=('(')^

















                                           ((
                                           ((
                                        '}'))
                                   ));$,='`'|
                                '!';$\=(')')^
                            '}';$:='.'^'~';$~
                        ='@'|'(';$^="\)"^  ((
                    '['));$/='`'|'.';
                $_='('^'}';$,='`'
                  |'!';$\="\)"^
                      '}';$:
                         =('.')^
                      '~';$~='@'|'(';
                 $^=')'^'[';$/='`'
                  |'.';$_="\("^
                      '}';$,
                          ="\`"|
                              '!';$\=
                                ')'^'}'    ;(
                                    $:)="\."^
                                        "\~";
                                           $~
                                           =(
                          '@')|'(';
                       $^=')'^"\[";$/=
                     '`'|'.';$_='('^'}';
                   $,='`'|'!';$\=')'^"\}";
                  $:='.'^            '~';$~
                 ='@'                   |'('
                 ;$^                      =((
                ')'                        ))
                ^((                        ((
                '['                        ))
                ));                       $/=
                 '`'                     |'.'
                 ;($_)                 ='('^
                   '}';$,='`'|'!';$\=(')')^
                    '}';$:='.'^'~';$~='@'
                      |'(';$^=')'^"\[";
                          $/=('`')|
                '.'                        ;(
                $_)                        =(
                '(')^'}';$,='`'|'!';$\=(')')^
                '}';$:='.'^'~';$~='@'|'(';$^=
                ')'^'[';$/='`'|'.';$_='('^'}'
                ;$,='`'|'!';$\=')'^'}';$:='.'
                ^((                   '~'
                                       ));
                                        $~=
                                        '@'|
                                        "\(";
                                    $^=(')')^
                                   '[';$/='`'
                                   |('.');$_=
                                   '('^"\}";
                                     ($,)

                =((                                            ((
                '`'                                            ))
                ))|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^=(')')^
                '[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^"\}";
                $:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|('.');$_=
                '('^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~';$~="\@"|
                '('

                         ;$^=')'^'[';
                       $/='`'|('.');$_=
                    '('^'}';$,='`'|'!';$\
                   =')'^'}';$:='.'^"\~";$~=
                 '@'|'(';           $^="\)"^
                 '[';                   ($/)=
                '`'|                      '.'
                ;$_                       =((
                 ((                       '('
                 )))                      )^+
                  '}'                    ;(
                    $,)                =(                      ((
                '`')))|'!';$\=')'^'}';$:='.'^'~';$~='@'|('(');$^=
                ')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\="\)"^
                '}';$:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|"\.";
                $_='('^'}';$,='`'|'!';$\=')'^'}';$:='.'^('~');$~=
                '@'
                |((

                '(')
                  );$^=
                     "\)"^
                        '[';$/
                            ='`'|
                               "\.";
                                  ($_)=
                                     "\("^
                                       "\}";
                                          ($,)=
                                             "\`"|
                                                '!';$\
                                                   ="\)"^
                                                       "\}";
                                                          ($:)=
                                                             '.'^

                '~'                        ;(
                $~)                        =(
                '@')|'(';$^=')'^'[';$/=('`')|
                '.';$_='('^'}';$,='`'|'!';$\=
                ')'^'}';$:='.'^'~';$~='@'|'('
                ;$^=')'^'[';$/='`'|'.';$_='('
                ^((                     ((
                                         ((
                                         '}')
                                         ))))
                                         );$,
                =((                     '`'))
                |'!';$\=')'^'}';$:='.'^'~';$~
                ='@'|'(';$^=')'^'[';$/=('`')|
                '.';$_='('^'}';$,='`'|"\!";
                $\=')'^'}';$:='.'^'~';$~=
                '@'

                                                     |'(';
                                                    $^=')'^
                                                   '[';$/="\`"|
                                                   '.';$_=
                                                    "\("^


                   '}'                  ;$,
                 ="\`"|                "\!";
                $\="\)"^              '}';$:=
            '.'^"\~";$~=              '@'|'('
               ;$^=')'^                "\[";

Let's get more ambitious and create a big self-printing I<JAPH>.

    my $src = <<'PROG';
    open 0;
    $/ = undef;
    $x = <0>;
    close 0;
    $x =~ tr/!-~/#/;
    print $x;
    PROG
    print sightly( { Shape         => 'japh',
                     SourceString  => $src,
                     Regex         => 1 } );

This works. However, if we were to change:

    $x =~ tr/!-~/#/;

to:

    $x =~ s/\S/#/g;

the generated program would malfunction in strange ways because
it is running inside a regular expression and Perl's regex engine
is not reentrant. In this case, we must resort to:

    print sightly({Shape        => 'japh',
                   SourceString => $src,
                   Regex        => 0 } );

which runs the generated sightly program via C<eval> instead.

To produce a I<JAPH> that resembles the original
I<Just another Perl hacker,> aka I<Randal L Schwartz>, try this:

    print sightly({ Shape        => 'merlyn',
                    SourceString => 'Just another Perl hacker,',
                    Regex        => 1,
                    Print        => 1 } );

producing:

                       ''=~('('.'?'.'{'.('['
                    ^'+').('['^')').('`'|')').(
                 '`'|'.').('['^'/').'"'.('`'^'*')
              .('['                          ^'.')
            .('['                              ^'(')
           .('['                                ^'/')
         .('{'^                                 '[').(
        "\`"|                                    '!').(
       '`'|                                      '.').(
      '`'|          (                (           '/'))).
    ('['            ^              ( (          '/'))).(
   '`'|           (              (  (         ( '('))))).
  ('`'|         (              (    (        (  '%'))))).
  ('['^       (              (    (        (    ')'))))).
  ('{'^      '[')        .(      (      ((      ('{'))))^
  '+').     (    '`'|'%'       ).("\["^         ')').('`'
 |',').('{'^                                    '[').('`'
 |'(').('`'                                      |"\!").(
 '`'|'#').(        ('`')|             '+').(     '`'|'%')
 .('['^')')     .((      ','       )).      '"'   .('}').
 "\)");$:=         ('.')^       (     "\~");      $~='@'|
 ('(');$^=       (( ')'  ))     ^   (( '['  ))     ;($/)=
  '`'|'.';       $_='('^'}'     ;   $,='`'|'!'      ;($\)
  =(')')^                       (                    '}'
   );($:)                       =                    '.'
    ^'~';                     ( ( (                  $~)
    )  )=                    (  (  (                 '@'
    )   )                   ) | ( ( (               '('
    )   )                   ) ; ( ( (               $^
    )   )                                          ) =
     (  (                                         ( (
      ( (                                         ( (
       (               ')')))))))))^'['     ;    # ;
        #        ;    #                ;    #    ;#
        ;        #     ;              #    ;    #;
        #        ;      #;          #;    #    ;
        #        ;        #       ;#      ;   #
        ;        #          ;#;#;        #   ;
         #        ;                     #   ;
         #        ;                    #   ;
          #        ;                      #
           ;       #                     ;
            #      ;                    #
             ;      #                  ;
              #                      ;
                #                  ;
                  #;#           ;#
                      ;#;#;#;#;

But wait, there's more. You can encode binary files too.

    print sightly({Shape      => 'camel,mongers',
                   SourceFile => 'some_binary_file',
                   Binary     => 1,
                   Print      => 1,
                   Gap        => 3 } );

This is prettier than I<uuencode/uudecode>.
Here is how you encode/decode binary files with F<sightly.pl>.

To encode:

    sightly.pl -g3 -bps camel,mongers -f some_binary_file >eyesore

To decode:

    perl eyesore >f.tmp

To verify it worked:

    cmp f.tmp some_binary_file

On a really slow day, you can sit at your Unix terminal and type
things like:

    sightly.pl -r -s camel -f helloworld.pl >t1.pl
    cat t1.pl
    perl t1.pl

Just one camel needed for this little program.

    sightly.pl -r -s camel -f t1.pl >t2.pl
    cat t2.pl
    perl t2.pl

Hmm. 13 camels now.

    sightly.pl -r -s camel -f t2.pl >t3.pl
    ls -l t3.pl
    cat t3.pl
    perl t3.pl

163 camels. 412,064 bytes. Hmm. Getting slower.
Is this the biggest, slowest I<hello world> program ever written?

    sightly.pl -r -s camel -f t3.pl >t4.pl
    ls -l t4.pl
    cat t4.pl
    perl t4.pl

2046 camels. 5,172,288 bytes. Out of memory!

Here is the original one camel program, F<t1.pl>:

                                         ''=~+(
                                        '('.'?' .'{'.
            ('`' |                  '%').("\["^ '-').(
        '`'|"\!").(               '`'|',').'"'.( ('[')^
   ('+')).(  "\["^ (             ')')).('`'|')').(('`')|
 '.').('['^'/').('{'^           '[').'\\'.'"'.('`'|'(').
 ('`'|'%').('`'|',').(        '`'|',').('`'|'/').('{'^'[')
  .('['^',').('`'|'/')     .('['^')').('`'|',').('`'|'$').'\\'
             .'\\'.(       '`'|'.').'\\'.'"'.';'.('!'^'+').'"'.
       '}'.')');$:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('
       ^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^"\[";
      $/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~';$~="\@"|
       '(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^"\}";$:=
       '.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';
       $\=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_="\("^
      '}';$,='`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^('[');$/=
       '`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';
         $^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}' ;($:)=
          '.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';   ($,)=
            '`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^=(')')^   "\[";
              $/='`'|'.';$_='('^'}';$,='`'|'!';$\=')' ^'}';$:=   '.'^
                ((   '~'));$~='@'|'(';$^=')'^"\[";$/= '`'|'.';  ($_)
                     ='('^"\}";  $,='`'|'!' ;$\=')'^   '}';$:=  '.'
                     ^('~');$~=  '@'|'(';$^ =')'^'['    ;$/='`' |+
                      "\.";$_=   '('^'}';$,  =('`')|     '!';$\
                      =')'^'}'  ;$:=('.')^   '~';$~=      "\@"|
                      '(';$^=   ')'^'[';$/    ="\`"|      '.';$_
                      =('(')^   "\}";$,=      ('`')|       "\!";
                      $\=')'    ^"\}";       $:='.'        ^'~';
                       ($~)=     ('@')|     '(';$^         =')'^
                       "\[";      $/='`'|  '.';$_          ='('
                       ^'}';         $,='`'|'!'            ;$\=
                       ')'^           "\}";$:=             '.'^
                       '~';            $~=('@')|           '(';
                      ($^)            =')'^'[';$/         ='`'|
                     "\.";         $_='('^'}';$,=         ('`')|
                     "\!";        $\="\)"^  '}';         $:='.'^
                   '~';$~=                              '@'|'(';
                 $^="\)"^                                '[';#;

Buffy fans might like to experiment with rotating her letters:

    print sightly( { Shape       => 'buffy',
                     Rotate      => 0,  # try 270, 90 and 180 too
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

while cricket fans could compare:

    print sightly( { Shape       => 'cricket',
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

which produces:

                     '?'
                    =~+(
                   "\(".
                  "\?".
                "\{".(
               ('`')|
              '%').(
             ('[')^
            '-').(    "\`"|
           '!').(   '`'|',')
      .'"'.('['    ^'+').('['
      ^"\)").(     '`'|"\)").(
    '`'|'.')       .('['^'/')
    .(('{')^       '[').'\\'.
  '"'.(('`')|       '(').('`'
 |'%').('`'|','      ).("\`"|
 "\,").( '`'|'/')    .('{'^'[').
 (('[')^  ',').('`'|'/').(('[')^
  "\)").(  '`'|',').('`'|'$').''.
   ('\\').  '\\'.('`'|"\.").'\\'.
     ('"').  ';'.('!'^'+').('"').
      '}'.')');$:='.'^'~';$~='@'|
      '(';$^=')'^'[';$/='`'|'.';$_
       ='('^'}';$,='`'|'!';$\=')'^
        '}';$:=   '.'^'~';$~="\@"|
         '(';      $^=')'^"\[";$/=
                   '`'|'.';$_='('^
                   '}';$,='`'|"\!";
                   $\=')'^('}');$:=
                   '.'^'~';$~="\@"|
                   '(';$^=')'^"\[";
                  $/='`'|'.';$_='('
                 ^'}';$,='`'|'!';$\=
               ')'^'}';$:='.'^'~';$~=
              '@'|'(';$^=')'^('[');$/=
              '`'|'.';$_='('^'}';$,='`'
             |'!';$\=')'^'}';$:='.'^'~';
            $~='@'|'(';$^=')'^'[';$/='`'|
     (     '.');$_='('^'}'   ;$,='`'|"\!";
      $\   =')'^"\}";$:=      '.'^('~');$~=
       '@' |'(';$^=')'^        '[';$/=('`')|
       '.';$_=('(')^            '}';$,=('`')|
       '!';$\=(')')^             '}';$:=('.')^
       '~';$~='@'|'('              ;$^=')'^'[';
        $/='`'|('.');$_=            '('^"\}";$,=
         '`'|'!';$\=')'^'}'           ;$:='.'^'~'
            ;$~='@'|('(');$^=          ')'^"\[";$/=
               '`'|'.';$_='('           ^'}';$,='`'|
                     '!';$\=              ')'^'}';$:=
                      "\."^                 '~';$~='@'|
                     "\(";                    $^=')'^'['
                     ;$/=                      '`'|'.';
                     $_=                         "\(";

to:

    print sightly( { Shape       => 'cricket',
                     Invert      => 1,
                     BorderWidth => 2,
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

which produces:

 ''=~('('.'?'.'{'.('`'|'%').('['^'-').('`'|'!').('`'|(',')).
 '"'.('['^'+').('['^')').('`'|')').('`'|'.').('['^'/').('{'^
 '[').'\\'.'"'.('`'|'('   ).('`'|'%').('`'|',').('`'|"\,").(
 '`'|'/').('{'^"\[").(    '['^',').('`'|'/').('['^')').('`'|
 ',').('`'|'$').'\\'.     '\\'.('`'|'.').'\\'.'"'.';'.("\!"^
 '+').'"'.'}'."\)");     $:='.'^'~';$~='@'|'(';$^=')'^'[';$/
 ='`'|'.';$_="\("^      '}';$,='`'|'!';$\=')'^'}';$:='.'^'~'
 ;$~='@'|"\(";$^=      ')'^'[';$/='`'|'.';$_='('^'}';$,='`'|
 '!';$\=')'^'}';      $:='.'^'~';$~='@'|'(';$^=')'^('[');$/=
 '`'|'.';$_='('      ^'}';$,='`'|'!';$\=')'^'}';$:='.'^"\~";
 $~='@'|'(';$^      =')'     ^'[';$/='`'|'.';$_='('^"\}";$,=
 '`'|"\!";$\=      ')'        ^'}';$:='.'^'~';$~='@'|'(';$^=
 ')'^'['         ;$/=          '`'|'.';$_='('^'}';$,='`'|'!'
 ;$\=')'        ^'}';           $:='.'^'~';$~='@'|'(';$^=')'
 ^'[';        $/='`'|          '.';$_='('^'}';$,='`'|'!';$\=
 "\)"^        '}';$:=          '.'^'~';$~='@'|'(';$^=')'^'['
 ;$/           =('`')|         '.';$_='('^'}';$,='`'|'!';$\=
 ((              ')'))^        '}';$:='.'^'~';$~='@'|'(';$^=
 ((       (        ')')           ))^'[';$/='`'|'.';$_="\("^
 ((       ((                      '}'))));$,='`'|'!';$\=')'^
 '}'       ;(                      $:)='.'^'~';$~='@'|'(';$^
 =')'       ^+                     '[';$/='`'|'.';$_='('^'}'
 ;($,)=      ((                    '`'))|'!';$\=')'^"\}";$:=
 '.'^'~'                           ;$~='@'|'(';$^=')'^'[';$/
 =('`')|                            '.';$_='('^'}';$,=('`')|
 "\!";$\=                           ')'^'}';$:='.'^('~');$~=
 '@'|"\(";       $^=                ')'^'[';$/='`'|('.');$_=
 '('^'}';$,    ="\`"|               '!';$\=')'^'}';$:=('.')^
 '~';$~='@'|('(');$^=               ')'^'[';$/='`'|('.');$_=
 '('^'}';$,='`'|"\!";                $\=')'^'}';$:='.'^"\~";
 $~='@'|'(';$^=(')')^                '[';$/='`'|'.';$_="\("^
 '}';$,='`'|('!');$\=                ')'^'}';$:='.'^"\~";$~=
 '@'|'(';$^=')'^"\[";                $/='`'|'.';$_='('^"\}";
 $,='`'|'!';$\="\)"^                 '}';$:='.'^'~';$~="\@"|
 '(';$^=')'^'[';$/=                   '`'|'.';$_='('^'}';$,=
 '`'|'!';$\="\)"^                      '}';$:='.'^'~';$~='@'
 |'(';$^=')'^'['                        ;$/='`'|'.';$_="\("^
 '}';$,='`'|'!';                         $\=')'^'}';$:="\."^
 '~';$~='@'|'('                           ;$^=')'^'[';$/='`'
 |'.';$_="\("^                             '}';$,='`'|'!';$\
 ="\)"^ "\}";               $:=             '.'^'~';$~="\@"|
 '(';$^=  ')'             ^"\[";             $/='`'|"\.";$_=
 '('^'}';   (            $,)='`'|             '!';$\=')'^'}'
 ;$:='.'^             '~';$~="\@"|             '(';$^=(')')^
 "\[";$/=             '`'|('.');$_=             '('^"\}";$,=
 '`'|'!';              $\=')'^'}';$:=            '.'^'~';$~=
 '@'|"\(";                $^=')'^"\[";            $/='`'|'.'
 ;$_=('(')^                  '}';$,='`'|           ('!');$\=
 ')'^('}');$:=                 '.'^'~';$~            =('@')|
 '(';$^=')'^"\[";              $/='`'|'.';            $_='('
 ^'}';$,='`'|'!';$\=')'       ^'}';$:=('.')^           "\~";
 $~='@'|'(';$^=')'^"\[";     $/='`'|'.';$_='('           ^((
 '}'));$,='`'|('!');$\=     ')'^'}';$:='.'^"\~";          $~
 ='@'|'(';$^=')'^'[';$/    ='`'|'.';$_='('^'}';$,        =((
 '`'))|'!';$\=')'^"\}";   $:='.'^'~';$~='@'|'(';$^=     ')'^
 '[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~';
 $~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|"\!";#;#

=head1 REFERENCE

=head2 Sightly Encoding

There are 32 characters in the sightly character set:

    ! " # $ % & ' ( ) * + , - . /            (33-47)
    : ; < = > ? @                            (58-64)
    [ \ ] ^ _ `                              (91-96)
    { | } ~                                  (123-126)

A I<sightly string> consists only of characters drawn from
this set.

The C<ascii_to_sightly> function converts an ASCII string
(0-255) to a sightly string; the C<sightly_to_ascii> function
does the reverse.

=head2 Function Reference

=over 4

=item ascii_to_sightly STRING

Given an ascii string STRING, returns a sightly string.

=item sightly_to_ascii STRING

Given a sightly string STRING, returns an ascii string.

=item regex_print_sightly STRING

Given an ascii string STRING, returns a sightly-encoded Perl
program with a print statement embedded in a regular expression.
When run, the program will print STRING.

=item regex_eval_sightly STRING

Given a Perl program in ascii string STRING, returns an
equivalent sightly-encoded Perl program using an eval
statement embedded in a regular expression.

=item clean_print_sightly STRING

Given an ascii string STRING, returns a sightly-encoded Perl
program with a print statement executed via eval.
When run, the program will print STRING.

=item clean_eval_sightly STRING

Given a Perl program in ascii string STRING, returns an
equivalent sightly-encoded Perl program using an eval
statement executed via eval.

=item regex_binmode_print_sightly STRING

Given an ascii string STRING, returns a sightly-encoded Perl
program with a binmode(STDOUT) and a print statement embedded
in a regular expression. When run, the program will print STRING.
Note that STRING may contain any character in the range 0-255.
This function is used to sightly-encode binary files.
This function is dodgy because regexs don't seem to like
binary zeros; use C<clean_binmode_print_sightly> instead.

=item clean_binmode_print_sightly STRING

Given an ascii string STRING, returns a sightly-encoded Perl
program with a binmode(STDOUT) and a print statement executed
via eval. When run, the program will print STRING.
Note that STRING may contain any character in the range 0-255.
This function is used to sightly-encode binary files.

=item get_builtin_shapes

Returns a list of the built-in shape names.

=item get_eye_shapes

Returns a list of the I<eye> shapes. An eye shape is just a
file with a F<.eye> extension residing in the same directory
as F<EyeDrops.pm>.

=item border_shape SHAPESTRING GAP_LEFT GAP_RIGHT GAP_TOP GAP_BOTTOM
WIDTH_LEFT WIDTH_RIGHT WIDTH_TOP WIDTH_BOTTOM

Put a border around a shape.

=item invert_shape SHAPESTRING

Invert a shape.

=item reflect_shape SHAPESTRING

Reflect a shape.

=item rotate_shape SHAPESTRING DEGREES

Rotate a shape clockwise thru 90, 180 or 270 degrees.

=item pour_sightly SHAPESTRING PROGSTRING GAP RFILLVAR

Given a shape string SHAPESTRING, a sightly-encoded program
string PROGSTRING, and a GAP between successive shapes,
returns a properly shaped program string. RFILLVAR is
a reference to an array of filler variables.
A filler variable is a valid Perl variable consisting
of two characters: C<$> and a punctuation character.
For example, RFILLVAR = C<[ '$:', '$^', '$~' ]>.

=item sightly HASHREF

Given a hash reference, HASHREF, describing various attributes,
returns a properly shaped program string.

The attributes that HASHREF may contain are:

    Shape         Describes the shape you want.
                  First, a built-in shape is looked for. Next, a
                  'eye' shape (.eye file in the same directory
                  as EyeDrops.pm) is looked for. Finally, a file
                  name is looked for.

    ShapeString   Describes the shape you want.
                  This time you specify a shape string.

    SourceFile    The source file name to convert.

    SourceString  Specify a string instead of a file name.

    BannerString  String to use with built-in Shape 'banner'.

    Regex         Boolean. If set, try to embed source program
                  in a regular expression. Do not set this flag
                  when converting complex programs.

    Print         Boolean. If set, use a print statement instead
                  of the default eval statement. Set this flag
                  when converting text files (not programs).

    Binary        Boolean. Set if encoding a binary file.

    Gap           The number of lines between successive shapes.

    Rotate        Rotate the shape clockwise 90, 180 or 270 degrees.

    Reflect       Reflect the shape.

    Invert        Invert the shape.

    Indent        Indent the shape. The number of spaces to indent.

    BorderGap     Put a border around the shape. Gap between border
                  and the shape.

    BorderGapLeft,BorderGapRight,BorderGapTop,BorderGapBottom
                  You can override BorderGap with one or more from
                  the above.

    BorderWidth   Put a border around the shape. Width of border.

    BorderWidthLeft,BorderWidthRight,BorderWidthTop,BorderWidthBottom
                  You can override BorderWidth with one or more from
                  the above.

    Width         Ignored for .eye file shapes. For built-in shapes,
                  specifies the shape width in characters.

    TrapEvalDie   Boolean.
                  Add closing 'die $@ if $@' to generated program.
                  When an eval code block calls the die function,
                  the program does not die; instead the die string
                  is returned to eval in $@. Using this flag allows
                  you to convert programs that call die.

    TrapWarn      Boolean.
                  Add leading 'local $SIG{__WARN__}=sub{};' to
                  generated program. This shuts up some warnings.
                  Use this option if generated program emits
                  'No such signal: SIGHUP at ...' when run with
                  warnings enabled.

    FillerVar     Reference to a list of 'filler variables'.
                  A filler variable is a Perl variable consisting
                  of two characters: $ and a punctuation character.
                  For example, FillerVar => [ '$:', '$^' ]

=back

=head2 Shape Reference

When you specify a shape like this:

    sightly( { Shape => 'camel' ...

EyeDrops looks for the file F<camel.eye> in the same
directory as F<EyeDrops.pm>.
You can also specify a shape with a file name:

    sightly( { Shape => '/tmp/camel.eye' ...

or with a string, for example:

    my $shapestr = <<'GROK';
             #####
    #######################
    GROK
    sightly ( { ShapeString => $shapestr ...

The shapes (F<.eye> files) distributed with this version of
EyeDrops are:

    bleach      banner of "use Acme::Bleach;"
    buffy       banner of "Buffy"
    buffy2      Buffy's angelic face
    camel       dromedary (Camelus dromedarius, one hump)
    cricket     Australia are world champions in this game
    damian      Damian Conway's face
    golfer      A golfer hitting a one iron
    japh        JAPHs were invented by Randal L Schwartz in 1988
    larry       Larry Wall's face
    larry2      Caricature of Larry contributed by Ryan King
    merlyn      Just another Perl hacker, aka Randal L Schwartz
    mongers     Perl Mongers logo
    santa       Santa Claus playing golf
    spoon       a wooden spoon
    uml         a UML diagram
    window      a window

It is easy to create your own shapes. For some ideas on shapes,
point your search engine at I<Ascii Art> or I<Clip Art>.
If you generate some nice shapes, please send them in so they
can be included in future versions of EyeDrops.

=head1 BUGS

A really diabolical shape with lots of single character lines
will defeat the shape-pouring algorithm.

You can eliminate all alphanumerics (via Regex => 1) only for
small programs with simple I/O and no regular expressions.
To convert complex programs, you must use Regex => 0, which
emits a leading unsightly C<eval>.

The code generated by Regex => 1 requires Perl 5.005 or higher
in order to run; when run on earlier versions, you will likely
see the error message: C<Sequence (?{...) not recognized>.

The converted program runs inside an C<eval> which may cause
problems for non-trivial programs. A C<die> statement or
an C<INIT> block, for instance, may cause trouble.
If desperate, give the C<TrapEvalDie> and C<TrapWarn>
attributes a go, and see if they fix the problem.

If the program to be converted uses the Perl format variables
C<$:>, C<$~> or C<$^> you may need to explicitly set the
C<FillerVar> attribute to a Perl variable/s not used by the program.

Linux F</usr/games/banner> does not support the following characters:

    \ [ ] { } < > ^ _ | ~

When the CPAN Text::Banner module is enhanced, it will be used
in place of the Linux banner command.

=head1 AUTHOR

Andrew Savige <andrew.savige@ir.com>

=head1 SEE ALSO

L<Acme::Bleach>
L<Acme::Smirch>
L<Acme::Buffy>

=head1 CREDITS

I blame Japhy and Ronald J Kimball and others on the fwp
mailing list for exposing the ''=~ trick, Jas Nagra for
explaining his C<Acme::Smirch> module, and Rajah Ankur
and Supremely Unorthodox Eric for provoking me.

I would also like to thank Ian Phillipps, Philip Newton,
Ryan King, Michael G Schwern, Robert G Werner, Simon Cozens,
and others on the fwp mailing list for their advice on
ASCII Art, imaging programs, and on which picture of
Larry to use.

=head1 COPYRIGHT

Copyright (c) 2001 Andrew Savige. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
