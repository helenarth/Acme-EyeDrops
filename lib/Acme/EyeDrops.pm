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
                reduce_shape expand_shape
                pour_sightly sightly);

$VERSION = '1.13';

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

# Return the largest number of compact tokens with combined
# length less than $slen.
sub _guess_compact_ntok {
   my ($rtok, $sidx, $slen, $rexact, $fcompact) = @_;
   my $eidx = $sidx + $slen + $slen;
   my $tlen = 0; my $ntok = 0;
   ${$rexact} = 0; ${$fcompact} = 0;
   for my $i ($sidx .. $eidx) {
      my $l = length($rtok->[$i]);
      if ($i > $sidx+1 && $rtok->[$i-1] eq '.'
      && substr($rtok->[$i],   0, 1) eq "'"
      && substr($rtok->[$i-2], 0, 1) eq "'") {
         ${$fcompact} = 1;
         $l -= 3;    # 'a'.'b' to 'ab' saves 3 chars
      }
      $tlen += $l;
      if ($tlen == $slen) {
         ${$rexact} = 1;
         if ($i > $sidx && $rtok->[$i] eq '.'
         && substr($rtok->[$i-1], 0, 1) eq "'"
         && substr($rtok->[$i+1], 0, 1) eq "'"
         && length($rtok->[$i+1]) == 3) {
            ${$fcompact} = 1;
            return $ntok+2;
         } else {
            return $ntok+1;
         }
      } elsif ($tlen > $slen) {
         return $ntok;
      }
      ++$ntok;
   }
   die "oops, slen=$slen, ntok=$ntok";
}

sub _compact_join {
   my ($rtok, $sidx, $n) = @_;
   my $eidx = $sidx + $n - 1;
   my $s = "";
   for my $i ($sidx .. $eidx) {
      if ($i > $sidx+1 && $rtok->[$i-1] eq '.'
      && substr($rtok->[$i],   0, 1) eq "'"
      && substr($rtok->[$i-2], 0, 1) eq "'") {
         # 'a'.'b' to 'ab'
         substr($s, -2) = substr($rtok->[$i], 1);
      } else {
         $s .= $rtok->[$i];
      }
   }
   $s;
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

# Pour $n tokens from @{$rtok} (starting at index $sidx)
# into string ${$rstr) of length $slen.
# Return 1 if successful, else 0.
sub _pour_compact_line {
   my ($rtok, $sidx, $n, $slen, $rstr) = @_;
   my $eidx = $sidx + $n - 1;
   my @mytok = ();
   for my $i ($sidx .. $eidx) {
      if ($i > $sidx+1 && $rtok->[$i-1] eq '.'
      && substr($rtok->[$i],   0, 1) eq "'"
      && substr($rtok->[$i-2], 0, 1) eq "'") {
         # 'a'.'b' to 'ab'
         pop(@mytok);
         my $qtok = pop(@mytok);
         push(@mytok, substr($qtok, 0, -1) . substr($rtok->[$i], 1));
      } else {
         push(@mytok, $rtok->[$i]);
      }
   }
   push(@mytok, $rtok->[$sidx+$n]);  # pour_line checks next token
   _pour_line(\@mytok, 0, scalar(@mytok)-1, $slen, $rstr);
}

# Pour program $prog into shape defined by string $tlines.
sub pour_sightly {
   my ($tlines, $prog, $gap, $rfillvar, $compact) = @_;

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
               $iendprog += $tlen if $sidx < $iendprog;
            } else {
               my $fcompact = 0;
               my $n = $compact ?
               _guess_compact_ntok(\@ptok, $sidx, $tlen,
                  \$exactfit, \$fcompact) :
               _guess_ntok(\@ptok, $sidx, $tlen, \$exactfit);
               if ($exactfit) {
                  if ($fcompact) {
                     $outstr .= _compact_join(\@ptok, $sidx, $n);
                  } else {
                     $outstr .= join("", @ptok[$sidx .. $sidx+$n-1]);
                  }
                  $sidx += $n;
               } else {
                  my $str = "";
                  while ($n > 0) {
                     my $b = $fcompact ?
                     _pour_compact_line(\@ptok, $sidx, $n, $tlen,
                        \$str) :
                     _pour_line(\@ptok, $sidx, $n, $tlen, \$str);
                     if ($b) {
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
                     $iendprog += $nleft if $sidx < $iendprog;
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
   join("\n", @a, "");
}

# Invert shape (i.e. convert '#' to space and vice-versa).
sub invert_shape {
   my ($tlines) = @_;
   my @a = split(/\n/, $tlines);
   my $maxlen = 0;
   for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
   for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                       if length($l) < $maxlen }
   my $s = join("\n", @a, "");
   $s =~ tr/ #/# /;
   $s;
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
   join("\n", @a, "");
}

# Reduce shape by a factor of $fact
sub reduce_shape {
   my ($tlines, $fact) = @_;
   ++$fact;
   my @a = split(/\n/, $tlines);
   my @n = ();
   my $i; my $j; my $l;
   for ($j = 0; $j < @a; $j += $fact) {
      $l = $a[$j]; my $s = "";
      for ($i = 0; $i < length($l); $i += $fact) {
         $s .= substr($l, $i, 1);
      }
      push(@n, $s);
   }
   join("\n", @n, "");
}

# Expand shape by a factor of $fact
sub expand_shape {
   my ($tlines, $fact) = @_;
   ++$fact;
   my @a = split(/\n/, $tlines);
   my @n = ();
   for my $l (@a) {
      my $s = join("", map { $_ x $fact } split("", $l));
      for (1 .. $fact) { push(@n, $s) }
   }
   join("\n", @n, "");
}

# Rotate shape clockwise: 90, 180 or 270 degrees
# (other angles are left as an exercise for the reader:-)
# rotate type $rtype = 0  big rotated shape
#             $rtype = 1  small rotated shape
#             $rtype = 2  squashed rotated
# flip = 1 to flip (reflect) shape in addition to rotating it
sub rotate_shape {
   my ($tlines, $degrees, $rtype, $flip) = @_;
   if ($degrees == 180) {
      return join("\n", reverse(split(/\n/, $tlines)), "");
   }
   my $mult = ($rtype == 0) ? 2 : 1;
   my $inc  = ($rtype == 1) ? 2 : 1;
   my @a = split(/\n/, $tlines);
   my $maxlen = 0;
   for my $l (@a) { $maxlen = length($l) if length($l) > $maxlen }
   for my $l (@a) { $l .= ' ' x ($maxlen - length($l))
                       if length($l) < $maxlen }
   my @n = ();
   if ($degrees == 90) {
      @a = reverse(@a) unless $flip;
      my $i;
      for ($i = 0; $i < $maxlen; $i += $inc) {
         my $line = "";
         for my $l (@a) { $line .= substr($l, $i, 1) x $mult }
         push(@n, $line);
      }
   } elsif ($degrees == 270) {
      @a = reverse(@a) if $flip;
      my $i;
      for ($i = $maxlen-1; $i >= 0; $i -= $inc) {
         my $line = "";
         for my $l (@a) { $line .= substr($l, $i, 1) x $mult }
         push(@n, $line);
      }
   }
   return join("\n", @n, "");
}

sub make_triangle {
   my $rarg = shift;
   my $width = $rarg->{Width};
   ++$width unless $width & 1;
   $width < 9 and $width = 9;
   my $height = int($width/2) + 1;
   my $str = ""; my $ns = $height; my $nf = 1;
   for (1 .. $height) {
      $str .= ' ' x --$ns . '#' x $nf . "\n";
      $nf += 2;
   }
   $str;
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
   $src =~ tr#_\\[]{}<>^|~'`#-/()()()H!T""#;
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
   $str;
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
   Compact           => 0,
   Print             => 0,
   Binary            => 0,
   Gap               => 0,
   Rotate            => 0,
   RotateType        => 0,
   RotateFlip        => 0,
   Reflect           => 0,
   Reduce            => 0,
   Expand            => 0,
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
   local *DD;
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
      local *SSS;
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
               local *SSS;
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
         $shapestr = rotate_shape($shapestr, $arg{Rotate},
                        $arg{RotateType}, $arg{RotateFlip});
      }
      if ($arg{Reflect}) {
         $shapestr = reflect_shape($shapestr);
      }
      if ($arg{Reduce}) {
         $shapestr = reduce_shape($shapestr, $arg{Reduce});
      }
      if ($arg{Expand}) {
         $shapestr = expand_shape($shapestr, $arg{Expand});
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
         $widthright = $arg{BorderWidthRight}
            if $arg{BorderWidthRight};
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

   return pour_sightly($shapestr, $sightlystr, $arg{Gap}, \@fill,
      $arg{Compact}) unless ($arg{TrapEvalDie} or $arg{TrapWarn});

   if ($arg{TrapEvalDie}) {
      if ($arg{TrapWarn}) {
         return 'local $SIG{__WARN__}=sub{};' .
            pour_sightly($shapestr, $sightlystr, $arg{Gap}, \@fill,
            $arg{Compact}) .
            "\n\n\n;die \$\@ if \$\@\n";
      } else {
         return pour_sightly($shapestr, $sightlystr, $arg{Gap},
                \@fill, $arg{Compact}) .
                "\n\n\n;die \$\@ if \$\@\n";
      }
   } else {
      return 'local $SIG{__WARN__}=sub{};' .
         pour_sightly($shapestr, $sightlystr, $arg{Gap}, \@fill,
         $arg{Compact});
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
    cat new.pl              (should look like a camel)
    perl new.pl             (should print "hello world" as before)

Notice that the shape C<'camel'> is just the file F<camel.eye> in
the same directory as F<EyeDrops.pm>, so you are free to add your
own new shapes as required.

=head2 Making Your Programs Easier to Understand

If your boss demands a UML diagram describing your program, you
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
it is a Windows program and see its UML structure too,
just by glancing at the code.

For Linux-only, you can apply its F</usr/games/banner> command
to the program's source text:

    print sightly( { Shape       => 'srcbanner',
                     Width       => 70,
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

The generated program is easier to understand than the
original because its characters are bigger and easier to read.

=head2 An Abbreviated History of Perl 6

Here is a summary of the Perl 6 development effort so far:

    print sightly( { Shape        => 'jon,larry,damian,simon,parrot',
                     Gap          => 3,
                     Regex        => 1,
                     Print        => 1,
                     SourceString => <<'END_HAIKU' } );
    Coffee mug shatters
    Larry Apocalyptic
    Parrot not a hoax
    END_HAIKU

producing:

                     ''=~(
                   '('."\?".
                  '{'.('['^'+'
                 ).('['^"\)").(
                 '`'|')').('`'|
                 '.').('['^'/').
                 '"'.('`'^'#').(
                 '`'|'/').(('`')|
                 '&').('`'|'&').(
                  '`'|'%').("\`"|
                  '%').('{'^'[').
                   ('`'|('-')).(
                     '['^"\.").(
                     '`'|"'").(
                    '{'^'[').('['^'(')
                   .('`'|'(').('`'|'!')
                   .('['^'/').('['^"\/").(
                   '`'|'%').('['^')').('['^"\(").(
                  '!'^'+').('`'^',').('`'|'!').('['^')').(
                 '['^')').('['^'"').('{'^'[').('`'^'!').('['^'+')
                .('`'|'/').('`'|'#').('`'|'!').('`'|',').('['^'"').
                ('['^'+').('['^'/').('`'|')').("\`"|        "\#").(
               '!'^'+').('{'^'+').('`'|('!')).(                 '['
               ^')').('['^')').('`'|"\/").(
               '['^'/').('{'^'[').('`'|'.')
               .('`'|'/').('['^'/').(('{')^
               '[').('`'|'!').('{'^'[').('`'
               |'(').('`'|'/').('`'|('!')).(
               '['^'#').('!'^'+').'"'.'}'.')'
               );$:='.'^'~';$~='@'|'(';$^=')'
               ^'[';$/='`'|'.';$_='('^'}';$,=
               '`'|'!';$\=')'^'}';$:='.'^'~';
               $~='@'|'(';$^=')'^'[';$/=('`')|
               '.';$_='('^'}';$,='`'|'!';$\=')'
      ^((      '}'));$:='.'^'~';$~='@'|"\(";$^=
 ')'^'[';$/    ='`'|'.';$_='('^'}';$,='`'|"\!";
 $\=')'^'}';$: ='.'^'~';$~='@'|'(';$^=')'^"\[";             $/
  ='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^"\}";$:=           (  (
  '.'))^'~';$~='@'|'(';$^=')'^'[';$/='`'|('.');$_=         (  (
 '('))^'}';$,='`'|'!';$\=')'^'}';$:='.'^'~';$~="\@"|    '(';$^=
 ')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^'}'; $:='.'^'~'
  ;$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=')'^
   '}';$:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('^"\}";$,=
    '`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^'[';$/='`'|"\.";
      $_='('^   "\}"; $,='`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^
                  =(  ')')^'[';$/='`'|'.';$_='('^'}';$,='`'|'!';$\=
                      ')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^'[';$/=
                      '`'|'.';$_='('^'}';$,='`'|('!');$\=   "\)"^
                     '}';$:='.'^'~';$~='@'|'(';$^=')'^'[';
                     $/='`'|'.';$_='('^'}';$,='`'|('!');$\=
                    ')'^'}';$:='.'^'~';$~='@'|'(';$^=(')')^
                   '[';$/='`'|'.';$_='('^'}';$,='`'|"\!";$\=
                   ')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^'[';
                  $/='`'|'.';$_='('^'}'  ;$,='`'|'!';$\="\)"^
                 '}';$:='.'^'~';$~='@'    |'(';$^=')'^'[';$/=
                '`'|'.';$_='('^'}';$,      ='`'|'!';$\=(')')^



                          '}';$:='.'^"\~";
                       $~='@'|'(';$^=')'^"\[";
                  $/='`'|'.';$_='('^'}';$,="\`"|
                "\!";                         ($\)
              =')'                              ^((
            '}')                                  );(
          $:)=                                   (  '.'
         )^((                                    (   '~'
        )));                                  $~  =    '@'
      |'('                                   ;     (    $^)
    =((                                    ((       ((   ')'
   )))                                   ))           )   ^((
  '['                                ));(              (   $/)
 )=(                             '`')                   |   '.'
 ;$_                         ='('                        ^   '}'
 ;$,                ='`'|'!';                            (   $\)
 =((              ((                                     (    ((
 ')'             ))                                       )   ))
 ))^            (                                         (   ((
 '}'            )                                          )));(
 $:)           =                                              ((
 '.'           )          )^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.'
 ;$_           ='('^'}';$,=    '`'|'!'    ;    (   $\)=')'     ^
 '}'           ;          ( $:)  =((  ((  (    ( ((  '.'  )))  )
 )))           )          ^ '~';$~="\@"|  (    ( '('));$^=')'  ^
 '['           ;          (               (    (               (
 $/   )))     )           =               (    ((              (
 ((   (  '`'))            )               )     ))             )
 |+   (                   (               (     ( (            (
 ((   (  '.'               )))))))));($_)=       ( '(')^'}';$,=
 ((    (                              (          (          (
  (     (                            (          (           (
   (     (                            ( '`'    )            )
    )      )))                              ))             )
     )       )                  )))|'!';$\=')'^'}';$:      =
      (      (                '.'))^'~';$~='@'|'(';$^=     (
       (     (               ')')))^'[';$/='`'|"\.";$_=   (
        (   (                '('))  )^'}';$,="\`"|  '!';  (
         ( (                 $\))  )              =  ')' ^
          ((                 '}'   ));$:='.'^'~';$~   =((
           (                                            (
           (                                           (
           (                                          (
          (       (                                  (
          (        (                                (
          (          (                             (
          (            (                          (
         (               (                       (   (
         (                 (                    (     (
        (                    '@'              ))       )
       )                          )))))))))))            )



                   )))))))))))))|+
                 '(';$^=')'^('[');$/=
               '`'|'.';$_='('^'}';$,='`'
             |'!'                     ;$\=
           ')'^                         '}';
         ($:)                             ='.'
        ^'~'                                 ;$~=
       '@'|                                   '(';
      ($^)                                     =')'
     ^'['                                       ;$/=
    '`'|                                         '.'
    ;$_=                                         '('^
   '}';                                    $,='`' |'!'
   ;$\=                                ')'^     (  '}'
   );(    $:)                  ='.'^'~'          ;  $~=
  '@'     |  '(';           $^=                  (  ')'
 )^+      (      '[');$/='`'                     |  '.'
 ;$_      =                                      (  '('
 )^+      (                                      (  '}'
 ));      (                                       ( $,)
 )=(     (                                        ( '`'
  )))    |                                        ( '!'
  );     (                                        ( $\)
 ) =(    (                                        ( ((
 (  ((  (                                         ( ((
 (   ')')       )))))))))              )))^((     '}'
 )    );(    $:)         =((        '.'      ))^  '~'
 ; $~  =(        '@')|'('             ;$^=')'      ^+
 ( (   ((      ((  '[')  ))    )    )) ;$/=  ((    (
 ( (  '`'       )))))|'.';     (    $_)='('^'}'    ;
 (  (  $,                      )                  )
  =    ((                      (                 ((
  (    '`'                     )                 ))
   )   ))|                     (                '!'
    );($\)=                    (                ')'
      )^'}'              ;     (    (          $:)
      )='.'              ^     (    (          '~'
      ));$~=             '@'|"\(";$^=         ')'^
      '[';$/                                  ='`'
      |'.';$_         ='('^'}';$,='`'|'!'    ;$\=
       ')'^'}';    $:='.'^'~';$~='@'|'(';$^ =')'
        ^'[';$/=  ((                     "\`"))|
        '.';$_="\("^  '}';$,='`'|'!';$\=  (')')^
         '}';$:='.'      ^'~';$~="\@"|    "\(";
          $^=')'^'['                    ;($/)=
           '`'|('.');$_=            '('^"\}";
            $,='`'|'!';$\=')'^'}';$:='.'^'~'
            ;$~='@'|'(';$^=')'^'[';$/=('`')|
             '.';$_='('^'}';$,='`'|('!');$\=
              ')'^'}';$:='.'^'~';$~='@'|'(';
               $^=')'^'[';$/='`'|'.';$_='('
                 ^'}';$,='`'|'!';$\=(')')^
                  '}';$:='.'^'~';$~="\@"|
                    '(';$^=')'^('[');$/=
                      '`'|'.';$_=('(')^
                         '}';$,='`'|



                     '!';$\=')'^"\}";
                  $:='.'^'~'; $~=('@')|
                '(';$^=')'^'[' ;$/='`'|'.'
               ;$_='('^"\}";$,= '`'|"\!";$\=
             ')'^'}';$:='.'^'~' ;$~='@'|"\(";
           $^=')'^'[';$/='`'|'.' ;$_='('^"\}";
          $,='`'|'!';$\=')'^"\}"; $:='.'^'~';$~
         ='@'|'(';$^=')'^"\[";$/= '`'|'.';$_='('
        ^'}';$,='`'|'!';$\=')'^'}' ;$:='.'^'~';$~
       ='@'|'(';$^=')'^'[';$/='`'| '.';$_='('^'}';
      $,='`'|'!';$\=(')')^     '}' ;$:     ='.'^'~'
      ;$~='@'|'(';$^=')'                    ^'[';$/
     ='`'|'.';$_=('(')^                      '}';$,=
     '`'|'!';$\=')'^'}'                       ;($:)=
    '.'^'~';$~='@'|'(';                       $^=')'
    ^'[';$/='`'|'.';$_=                        "\("^
   '}';$,='`'|"\!";$\= (                       ')')
   ^'}';$:='.'^'~';$~  =                        '@'
   |'(';$^=')'^'[';$/  =                        ((
   '`'))|'.';$_="\("^  (                        ((
   '}')));$,='`'|'!'; (   ( ( (          (   (  (
   $\)))))))=')'^"\}"; (        (      (        (     (
   $:)))))='.'^'~';$~    ='@'|            '('  ;      (
 (   $^))=')'^'[';$/    ='`'|'.'         ;($_) =     (
   (  '('))^'}';$,                             =    (
     '`')|"\!";                      (          $\)
      =  ')'                         ^          (
      (                              (          (
      (                              (          (
       (    (                                   (
        ( ( (                   (     (  (      (
            (                  (      (  (      (
            (                  (      (  (
            (                                  (
         (   (
         (    (                   '}'))))))   )
         )     )             )))))))))))))
         )      )               ))))))))     ;
         (       (                 $:))='.'^'~';
         (         (           (                 (
         (             (     (                    (
          (                (                       (
                          (          (  (  (        (
           (                     (
                         (                           (
                              (                       (
                        (    (                         (
                            (                           (
                       ( ( (                             (



                                          $~)))))))
                                       ))))))))))))))
                                    ))))))))))='@'|"\(";
                                $^=')'^'[';$/='`'|'.';$_=
                              '('^'}';$,=('`')|   '!';$\=
                          ')'^'}';$:='.'^'~';$~   ='@'|'('
                      ;$^=')'^'[';$/='`'|'.';$_='('^'}';$,
                   ='`'|'!';$\=')'^'}';$:='.'^'~';$~="\@"|
                '(';$^=')'^'[';$/='`'|'.';$_='('^('}');$,=
              '`'|'!';$\=')'^'}';$:='.'^'~';$~='@'|'(';$^=
            ')'^'[';$/='`'|'.';$_='('^'}';$,='`'|"\!";$\=
           ')'^'}';$:='.'^'~';$~='@'|'(';$^=')'^     '['
          ;$/='`'|'.';$_='('^'}';$,='`'|'!';$\=    ')'
         ^'}';$:='.'^'~';$~='@'|'(';$^=')'^'['
        ;$/='`'|'.';$_='('^'}';$,='`'|'!';$\=
       ')'^'}';$:='.'^'~';$~='@'|'(';$^="\)"^
      '[';$/='`'|'.';$_='('^'}';$,='`'|"\!";
      $\=')'^'}';$:='.'^'~';$~='@'|('(');$^=
     ')'^'[';$/='`'|'.';$_='('^'}';$,="\`"|
     '!';$\=')'^'}';$:='.'^'~';$~='@'|'(';
    $^=')'^'[';$/='`'|'.';$_='('^"\}";$,=
    '`'|'!';$\=')'^'}';$:='.'^('~');$~=
   '@'|'(';$^=')'^'[';$/='`'|"\.";$_=
   '('^'}';$,='`'|'!';$\=')'^"\}";$:=
  '.'^'~';$~='@'|'(';$^=')'^('[');$/=
  '`'|'.';$_='('^'}';$,='`'|"\!";$\=
 ')'^'}';$:='.'^'~';$~='@'|('(');$^=
 ')'^'[';$/='`'|'.';$_='('^"\}";$,=
 '`'|'!';$\=')'^'}';$:='.'^"\~";$~= '@'
 |'(';$^=')'^'[';$/='`'|'.';$_='('^     (
 '}');$,='`'|'!';$\=')'^('}');$:=     '.'^
 '~';$~='@'|'(';$^=')'^('[');$/=    '`'|'.'
 ;$_='('^'}';$,='`'|'!';$\=')'^   '}';$:='.'^
 '~';$~='@'|'(';$^=')'^'[';$/=   '`'|'.';$_='('
 ^'}';$,='`'|"\!";$\=       ((  ')'))^'}';$:='.'^
 '~';$~='@'|('(');$^=        (  ')')^'[';$/='`'|'.'
 ;$_='('^'}';$,="\`"|         ( ( '!'));$\=')'^'}';
 $:='.'^'~';$~='@'|'('         ;     $^=')'^'[';$/=
 '`'|'.';$_='('^'}';$,                  ='`'|"\!";
 ($\)  =')'^'}';$:='.'                     ^'~';$~
 =((   '@'))|('(');$^=                        ')'
 ^+    '[';$/='`'|"\.";
 (     $_)='('^"\}";$,=
       '`'|'!';$\="\)"^
       '}';$:='.'^"\~";

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

=head2 Just another Perl hacker

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
If you want to use Regex => 1, ensure the program to be converted
is careful with its use of regular expressions and C<$_>.

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

=head2 Buffy Looking in the Mirror

Because the I<sightly> encoding is not very compact, you sometimes
find yourself playing a surreal form of I<Perl Golf>, where
the winner is the one with the smallest F<f.tmp> in:

    sightly.pl -r -f program_to_be_converted >f.tmp

Apart from reducing the (key-)stroke count, you must avoid regexes
and strive to replace alphanumeric characters with sightly ones,
which do not require sightly encoding.

To illustrate, consider the intriguing problem of creating
I<Buffy looking in the mirror>. Let's start with F<k.pl>:

    open$[;chop,($==y===c)>$-&&($-=$=)for@:=<0>;
    print$"x-(y---c-$-).reverse.$/for@:

Notice that EyeDrops-generated programs contain no trailing
spaces, which complicates the above program.

Buffy looking in the mirror can now be created with:

    sightly.pl -r -f k.pl -s buffy2 >b.pl
    cat b.pl        (should show Buffy's face)
    perl b.pl       (should show Buffy looking in the mirror)

Drat. This requires two I<buffy2> shapes. What to do?
Well, you could write a post processor program, F<pp.pl>,
to append the required number of spaces to each line:

    chop,$==y===c,$=<$-or$-=$=for@a=<>;
    print$_.($"x($--length)).$/for@a

With this program in place, we can write a briefer F<kk.pl>:

    open$%;chop,print+reverse.$/for<0>

and finally produce I<Buffy looking in the mirror> with:

    sightly.pl -r -f kk.pl -s buffy2 >b.pl
    perl pp.pl b.pl >bb.pl

For this example, however, the C<Compact> attribute (C<-m> switch
to F<sightly.pl>) provides a more direct solution,
without requiring any trailing spaces:

    sightly.pl -mr -f k.pl -s buffy2 >buffy.pl
    cat buffy.pl     (should show Buffy's face)
    perl buffy.pl    (should show Buffy looking in the mirror)

producing F<buffy.pl>:

                    ''=~('(?{'.(
                 '`'|'%').('['^'-'
               ).('`'|'!').('`'|','
              ).+               ( '"'
             ).(                (  '`'
            )|+                 (   '/'
           )).                  (   '['
          ^((                  (     '+'
         )))              ).('`'      |((
         '%'          ))).      (     '`'
        |((       '.')           )     ).+
        (((     ((                (     (((
        (((    (                   (    (((
        (((   (                     '\\')))
       )))    )                      ) )  )
       )   )))) ))))))      .'$[;'     .  (
       (  (  ((                        (  (
       (  (      ( (( (     ( (( (     (   (
       (  (       '`')       ))))      )   )
       )   )                        )))    )
       )    )))                     )      )
       )|      (       (   (        (     ((
       '#'      )        )          )    )))
        ).(('`')|                   ('(')).(
        '`'|'/').    ('['^'+')     .',(\\$'
        .'=='.('['     ^'"')     . '==='.+(
        '`'|'#').')'            .  '>\\$-'
        .'&&(\\$-=\\'          .   '$=)'.(
        '`'|'&').('`' |      (     '/')).(
        '['^')').'\\'     .        '@:=<' .
        ('^'^(('`')|              "\.")).   (
        '>').(';').(              '!'^'+'     )
         .('['^'+').             ('['^')'     ).('`'|
         ')').("\`"|             "\.").(      (      ('['))^
   "\/").'\\$\\"'.(            ( "\[")^       (             (
  (    ( "\#"))))). (        (   '-'))        .              (
 (     ( ('(')))).(   (   (     '['))         ^              (
 (     '"'))).'--'       .     '-'.           (              (
 (    '`'))|'#').        (                    (               (
 (     '-')))).          (                    (               (
 (     ( '\\'                                 )               )
 )     )                                      )               .
 (     (                                      (               (
 (     (                                      (      (         (
 (     (                                      (      (         (
 (     (                                      (     (          (
 (     (                                      (     (          (
 (     '$'))))))))))))))))))))))))).'-).'.('['^    (           (
 (    ')')))).('`'|'%').('['^'-').('`'|'%').(('[')^            (
 (    ')'))).('['^'(').('`'|'%').'.\\$/'.('`'|'&').(           (
 (   '`'))|'/').('['^')').'\\@:'.('!'^'+').'"})');$:=          (
 (   '.'))^'~';$~='@'|'(';$^=')'^'[';$/='`'|'.';$_='('         ;

This is perhaps a cleaner solution, though some people
find the plain sightly encoding more pleasing to the eye.

Interestingly, showing the face upside down, rather than
reflected, is more easily solved with:

    open$%;print+reverse<0>

and easier still for a self-printing shape:

    open$%;print<0>

=head2 A Somersaulting Camel

Let's extend the Buffy example of the previous section to produce
a camel-shaped program capable of somersaulting across the screen
when run.

We start with a generator program, F<gencamel.pl>:

    use Acme::EyeDrops qw(sightly);
    my $src = <<'END_SRC_STR';
    $~=pop||'';open$%;
    y,!-~,#,,s,(.).,$+,gs,$~&&($_=reverse)for@~=grep$|--,('')x18,<0>;
    @;=map~~reverse,reverse@~;
    map{system$^O=~Win?CLS:'clear';
    ($-=$_%3)||(--$|,map$_=reverse,@~,@;);
    print$"x($=/3*abs$|*2-$-),$_,$/for$-&1?@;:@~;
    sleep!$%}$%..11
    END_SRC_STR
    $src =~ tr/\n//d;
    my $prog = sightly( { Regex         => 1,
                          Compact       => 1,
                          Shape         => 'camel',
                          SourceString  => $src } );
    my @a = split(/\n/, $prog);
    my $max = 0; length > $max and $max = length for @a;
    $_ .= ' ' x ($max - length) for @a;
    print " $_ \n" for @a;

Note the use of the Compact attribute, necessary here to
squeeze the above program into a single camel shape.

Running this program:

    perl gencamel.pl >camel.pl

produces F<camel.pl>:

                                       ''=~('(?{'.(                
            ('`')|                   '%').('['^'-').               
         ('`'|'!').                ('`'|',').'"\\$~='              
  .('['^'+')  .('`'|              '/').('['^'+').'||'.             
 "'"."'".';'.('`'|'/'            ).('['^'+').('`'|'%').            
 ('`'|'.').('\\$%;').(          '['^'"').(',!-~,#,,').(            
   '['^'(').',(.).,\\'        .'$+,'.('`'|"'").('['^'(')           
        .',\\$~&&(\\$'      .'_='.('['^')').('`'|('%')).(          
       '['^'-').('`'|     '%').('['^')').('['^'(').(('`')|         
      '%').')'.("\`"|   '&').('`'|'/').('['^"\)").'\\@~='.(        
     '`'|"'").("\["^   ')').('`'|'%').('['^'+').('\\$|--,(').      
     "'"."'".(')').(  '['^'#').('^'^('`'|'/')).(':'&'=').',<'.     
     ('^'^('`'|'.')  ).'>;\\@;='.('`'|'-').('`'|'!').('['^'+')     
     .'~~'.('['^')'  ).('`'|'%').('['^'-').('`'|'%').('['^')').    
     ('['^'(').('`'|'%').','.('['^')').('`'|'%').('['^'-').('`'    
     |'%').('['^')').('['^'(').('`'|'%').'\\@~;'.('`'|'-').('`'|   
      '!').('['^'+').'\\{'.('['^'(').('['^'"').('['^'(').(('[')^   
      '/').('`'|'%').('`'|'-').'\\$^'.('`'^'/').'=~'.('{'^"\,").(  
       '`'|')').('`'|'.').'?'.('`'^'#').('`'^',').('{'^'(').(':'). 
        "'".('`'|'#').('`'|',').('`'|'%').('`'|'!').('['^')')."'". 
         ';(\\$-=\\$_%'.('^'^('`'|'-')).')||(--\\$|,'.('`'|'-' ).( 
          '`'|'!').('['^'+').'\\$_='.('['^')').('`'|'%').('['  ^(( 
           '-'))).('`'|'%').('['^')').('['^'(').('`' |('%')).  ',' 
             .'\\@~,\\@;);'.('['^'+').('['^(')')).(  '`'|')'   ).( 
              "\`"| '.').('['^'/').'\\$\\"'.("\["^   ('#')).   '(' 
                    .'\\$=/'.('^'^('`'|'-')).'*'.    (('`')|   '!' 
                    ).("\`"|    '"').('['^ "\(").     '\\$|'   .+  
                    ('*').(     '^'^('`'   |','))     .'-\\'  .+   
                    '$-),'.     '\\$_,'.   '\\$'       .'/'.  (    
                    ('`')|      ('&')).(   '`'|         '/')       
                    .('['^     ')').'\\'   .'$'         .'-'       
                     .'&'.     (('^')^(    '`'|         '/')       
                     ).'?'     .'\\@;'     .':'         .''.       
                     '\\'     .'@~;'       .''.         ('['       
                     ^'('     ).(          '`'|         ',')       
                     .''.      (((         '`'          ))|        
                     '%'        ).(       '`'           |((        
                     '%'         )))     .+(            '['        
                     ^((          '+'   )))              .+        
                     ((             '!')).               ((        
                     ((              '\\')               ))        
                     ).             '$%\\}'.             ((        
                    (((            '\\' )))))            .+        
                   '$'           .'%..'  .''.           (((        
                  '^')         )^("\`"|   '/'          )).(        
                "\^"^(                                ('`')|       
              ('/'))).                               '"})');       

I<Note: The use of a camel image in association with Perl is a
trademark of O'Reilly & Associates, Inc. Used with permission>.

You can run F<camel.pl> like this:

    perl camel.pl           normal forward somersaulting camel
    perl camel.pl b         camel somersaults backwards
    perl camel.pl please do a backward somersault
                            same thing

You are free to add a leading C<#!/usr/bin/perl -w> line to
F<camel.pl>, so long as you also add a blank line after
this header line.

=head2 Twelve Thousand and Thirty Two Camels

In a similar way to the somersaulting camel described above,
we create a camel-shaped program capable of emitting
twelve thousand and thirty two different camels when run.

As usual, we start with a generator program, F<gencamel.pl>:

    use Acme::EyeDrops qw(sightly);
    my $src = <<'END_SRC_STR';
    $~=uc shift;$:=pop||'#';open$%;chop(@~=<0>);$~=~R&&
    (@~=map{$-=$_+$_;join'',map/.{$-}(.)/,@~}$%..33);
    $|--&$~=~H&&next,$~!~Q&&eval"y, ,\Q$:\E,c",$~=~I&&
    eval"y, \Q$:\E,\Q$:\E ,",$~=~M&&($_=reverse),
    print$~=~V?/(.).?/g:$_,$/for$~=~U?reverse@~:@~
    END_SRC_STR
    $src =~ tr/\n//d;
    my $prog = sightly( { Regex         => 1,
                          Compact       => 1,
                          Shape         => 'camel',
                          SourceString  => $src } );
    my @a = split(/\n/, $prog);
    my $max = 0; length > $max and $max = length for @a;
    $_ .= ' ' x ($max - length) for @a; $\ = "\n";
    print ' ' x ($max+2); print " $_ " for @a; print ' ' x ($max+2);

Running this program:

    perl gencamel.pl >camel.pl

produces F<camel.pl>, which you can run like this:

    perl camel.pl           normal camel
    perl camel.pl q         quine (program prints itself)
    perl camel.pl m         mirror (camel looking in the mirror)
    perl camel.pl i         inverted camel
    perl camel.pl u         upside-down camel
    perl camel.pl r         rotated camel
    perl camel.pl h         horizontally-squashed camel
    perl camel.pl v         vertically-squashed camel

And can further combine the above options, each combination
producing a different camel, for example:

    perl camel.pl uri

produces a large, bearded camel with a pony-tail, glasses,
and a tie-dyed T-shirt. :)

F<camel.pl> also accepts an optional second argument, specifying
the character to fill the camel with (default C<#>).
For example:

    perl camel.pl hv        small camel filled with #
    perl camel.pl hv "$"    small camel filled with $

Why 12,032 camels? Combining the main options q, m, i, u, r, h, v
can produce 128 different camels. And there are 94 printable
characters available for the second argument, making a total
of 128 * 94 = 12,032 camels.

=head2 Sierpinski Triangles

Sierpinski triangle generators have proved popular on various
Perl mailing lists and at Perl monks too.

The shortest known Sierpinski triangle generator, F<siertri.pl>, is:

    #!perl -l
    $x=2**pop;print$"x--$x,map$x&$_?$"x2:"/\\",0..$y++while$x

which was posted by Mtv Europe to golf@perl.org on 14-sep-2002
as a one stroke improvement on Adam Antonik's original program.
Running this program:

    perl siertri.pl 4

displays a Sierpinski triangle with 2**4 lines.

An interesting obfuscated Sierpinski triangle generator is:

    #!perl -l
    s--(G^g)x(1<<pop)-ge,s-.-s,,,,s,$,(G^'/').(E^'|')^Ge,ge,
    print,s,(?<=/[^ge])[^g][^e],$&^(G^'/').(E^'|')^gE,ge-ge

As an alternative obfu, you can produce a Sierpinski triangle-shaped
Sierpinski triangle generator based on Mtv's program like this:

    use Acme::EyeDrops qw(sightly);
    my $src = <<'END_SRC';
    $-=!$%<<(pop||4);print$"x$-,map($-&$_?'  ':'/\\',$%..$.++),$/while$---
    END_SRC
    $src =~ tr/\n//d;
    print sightly( { SourceString    => $src,
                     Regex           => 1,
                     Compact         => 1,
                     Indent          => 1,
                     BorderGap       => 1,
                     BorderWidth     => 2,
                     Shape           => 'siertri' } );

producing:

 ''=~('(?{'.('`'|'%').('['^'-').('`'|'!').('`'|"\,").'"\\$-=!\\$%<<('.(
 '['^'+').('`'|'/').('['^'+').'||'.('^'^('`'|'*')).');'.('['^'+').('['^
 ((                                                                  ((
 ((                                ((                                ((
 ((                               ')')                               ))
 ))                              ))  ))                              ))
 ))                             .(('`')|                             ((
 ((                            ((      ((                            ((
 ((                           ')')    ))))                           ))
 ))                          ))  ))  .(  ((                          ((
 ((                         '`'))))))|'.').(                         ((
 ((                        ((              ((                        ((
 ((                       '[')            ))))                       ))
 ))                      ))  )^          ((  ((                      ((
 ((                     '/')))))        )))).''.                     ((
 ((                    ((      ((      ((      ((                    ((
 ((                   '\\'    ))))    ))))    ))))                   ))
 ))                  .+  ((  ((  ((  ((  ((  ((  ((                  ((
 ((                 '$')))))))))))))))))).'\\"'.('['                 ^+
 ((                ((                              ((                ((
 ((               '#')                            ))))               ))
 ))              ))  .+                          ((  ((              ((
 ((             '\\'))))                        )))).'$'             .+
 ((            ((      ((                      ((      ((            ((
 ((           '-')    ))))                    ))))    ))))           ).
 ((          ((  ((  ((  ((                  ((  ((  ((  ((          ((
 ((         ',')))))))))))))                ))))))))).("\`"|         ((
 ((        ((              ((              ((              ((        ((
 ((       '-')            ))))            ))))            ))))       ))
 ))      .(  ((          ((  ((          ((  ((          ((  ((      ((
 ((     '`')))))        ))))))))        )))))|((        '!'))).(     ((
 ((    ((      ((      ((      ((      ((      ((      ((      ((    ((
 ((   '[')    ))))    ))))    ))))    ))))    ))))    )))^    '+')   .+
 ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((  ((
 (( '(')))))))))))))))))))))))))))))))))))))).'\\$-&\\$_?'."'".('{'^ ((
 ((                                                                  ((
 '['))))))).('{'^'[')."'".':'."'".'/\\\\\\\\'."'".',\\$%..\\$.++),\\$/'
 .('['^',').('`'|'(').('`'|')').('`'|',').('`'|'%').'\\$---"})');$:='.'

=head2 Dueling Dingos

During the TPR02 Perl Golf tournament, I<`/anick> composed a poem
describing his experience, entitled I<Dueling Dingos>.

You can produce a program that emits his moving poem like this:

    print sightly( { Shape        => 'yanick3',
                     Regex        => 1,
                     Print        => 1,
                     SourceString => <<'END_DINGO' } );
    #!/usr/bin/perl
    # Dueling Dingos v1.1, by Yanick Champoux (9/4/2002)
    #
    # Inspired by the TPR(0,2) Perl Golf contest.
    # Name haven't been changed, since the involved
    # parties could hardly be labelled as 'innocent',
    # and are way far too gone to protect anyway.

    wait until localtime > @April[0];  # wait until the first of April

    BEGIN{}

    study and seek FOR, $some, $inspiration;

    write $stuff;

    $score = 145; # no good;

    delete $stuff { I_can_do_without }
       and do $more_stuff;

    delete $even{more_stuff};

    reverse $engineer; study; eval $strategy and redo;

    write, write, write;
    delete $_{'!'}, delete $"{"@!"}, delete $@{'*'}; # must stop cursing

    use less 'characters', $durnit;

    read THE, $current, $solution;

    not 2, $bad;

    delete $white_spaces{''} until $program == glob;

    for( $all, my @troubles )
    {
        unlink 1, $character;
    }

    ARGH:

    $must, not $despair;

    $I->can(do{ $it });

    study new Idea;

    m/mmmm/m... do{able};

    kill $chickens;

    'ask', $Nanabozo, 2, bless $me, 'with more inspiration';

    $so, close; warn $mailing_list and alarm $Andrew;

    $toil until my $solution < /-\ndrew's
    /;

    GOT_IT:

    send $solution, $to, ref;

    $brain, shutdown  I,'m dead';

    goto sleep;

    wait; $till, $the, $day, $after;

    readline last $scoreboard;

    grep $all, stat;

    read THE, $stats, $again until $it_sinks_in;

    $Andrew,'s score' lt $mine;

    $eyeball, pop @o
    ;
    END_DINGO

The generated program, being 2577 lines long, is not reproduced here.
To generate a shorter program summarising I<`/anick>'s TPR02 anguish:

    print sightly( { Shape        => 'yanick,eye,mosquito,coffee',
                     Gap          => 3,
                     Regex        => 1,
                     Print        => 1,
                     SourceString => <<'END_SUFFERING' } );
    My head is hurting, my right eye feels like it's going to pop
    like a mosquito drinking from an expresso addict with high
    blood pressure, I want to crawl somewhere damp and dark and
    quiet and I consider never to touch a keyboard again.
    END_SUFFERING

producing:

                             ''=~('('.'?'.'{'.(
                          '['^'+').('['^')').('`'|
                        ')').('`'|'.').('['^'/').'"'
                      .('`'^'-').('['^'"').('{'^'[').(
                     '`'|'(').('`'|'%').('`'|'!').("\`"|
                    '$').('{'^'[').('`'|')').('['^('(')).(
                   '{'^'[').('`'|'(').('['^'.').('['^"\)").(
                  '['^'/').('`'|')').('`'|'.').('`'|"'").','.
                 ('{'^'[').('`'|'-').('['^'"').('{'^'[').('['^
                 ')').('`'|')').('`'|"'").('`'|'(').('['^'/').(
                '{'^'[').('`'|'%').('['^'"').('`'|'%').('{'^'['
               ).('`'|'&').('`'|'%').('`'|'%').('`'|',').(('[')^
              '(').('{'^'[').('`'|',').('`'|')').('`'|'+').("\`"|
             '%').('{'^'[').('`'|')').           ('['^    ('/')).
            "'".('['^'(').('{'^'[').                       ("\`"|
            "'").('`'|'/').('`'|')'                         ).''.
           ('`'|'.').('`'|"'").('{'                         ^'[')
     .('[' ^'/').('`'|'/').(('{')^                          '[').
  ('['^'+'  ).('`'|'/').('['^'+').                          ('!'^
 '+').('`'  |',')  .('`'|(')')).(                           "\`"|
 '+').('`'  |'%'    ).('{'^'[').                            ('`'|
 '!').('{'     ^      ('[')).(                              "\`"|
 '-').('`'     |      "\/").(                               "\["^
 '(').('['     ^       '*'                                   ).(
 '['^'.'       )     .+(             (  ( (            ( (    (
 '`')))        )   ))                         |      (        (
 ')'))         )                   .               (         (
 '[')^         (                                            (
 '/'))         )                      .('`'|        '/').  (
 "\{"^          '['                   ).('`'        |'$') .
 ('['^           (                                (      (
 ')'))            )                               )     .
 ('`'|            (                  ')'))        .     (
 "\`"|             (            '.'))              .   (
 "\`"|              (                               ( (
 '+')))              )           .(         (       (
 "\`"))|              (           ((         (       (
 ')'))))))             .           +(         (     (
 '`'))|'.').(           (           ((          ( (
 '`')))))|"'").('{'^'[').(            ((         (
 '`')))|'&').('['^')').('`'|            ((     (
 '/')))).('`'|'-').('{'^'[').             ('`'
 |'!').('`'|'.').('{'^'[').('`'             |
 '%').('['^'#').('['^'+').("\["^          (
 ')')).('`'|'%').('['^('(')).(     '['^'('
 ).('`'|'/').('{'^'[').("\`"|
 '!').('`'|'$').('`'|"\$").(



                          '`'|')').(('`')|
                    (  '#')).('['^'/').("\{"^  (
                (    '['))).('['^',').('`'|')')    .
             (     '['^'/').('`'|'(').('{'^'[').(     (
          (       '`'))|'(').('`'|')').('`'|"'").(       (
        (        '`'))|'(').('!'^'+').('`'|('"')).(        (
      (          '`'))|',').('`'|'/').('`'|('/')).(          (
    (           '`'))|'$').('{'^'[').('['^'+').('['^           (
  (             ')'))).('`'|'%').('['^'(').('['^'(')             .
 (              '['^'.').('['^')').('`'|'%').(',').(              (
  (             '{'))^'[').('`'^')').('{'^'[').('['^             (
    (           ','))).('`'|'!').('`'|'.').('['^'/')           .
      (          '{'^'[').('['^'/').('`'|'/').('{'^          (
        (        '['))).('`'|'#').('['^')').(('`')|        (
          (       '!'))).('['^',').('`'|',').('{'^       (
             (     '['))).('['^'(').('`'|('/')).(     (
                (    '`'))|'-').('`'|'%').('['^    (
                    (  ','))).('`'|'(').('`'|  (
                          '%')).('['^')').



              +(                                                 ((
             '`'))                                             |  (
            "\%")).(                                         (   (
            '{'))^'['                 )  .                 (   (
            '`')|'$').(               (  (               (   (
            '`'))))|'!')              .  (            (   (
             '`'))|'-').(             (  (          (   (
              '['))))^'+')            .  (        (    (
               '{'))^'[').(           (  (     (    (
                 '`'))))|'!'          ) .   (     (
    '`')|'.'       ).('`'|'$'         ) .  (  (
 '{')^'[').('`'|      ('$')).(  '`'| '!' )  .
 ('['^')').('`'|'+')     .('{'^'[').('`'| (
  '!')).('`'|'.').('`'|'$').('!'^"\+").( (
   '[')^'*').('['^'.').('`'|')').('`'|'%'
    ).('['^'/').('{'^'[')   .('`'|'!').
      ('`'|('.')).(       '`'|('$')).(
                             '{'^'['
                            ).( '`'
                           ^+ ( ( (
                           (( ( ( (
                          (( ( (  (
                         (( (  (  (
                        ((  ( (   (
                     ')')  )  )   )
                      )) ) )  )   )
                         ) )  )   )
                         ) )  )  )
                         ) ) )   )
                        )  ) .   (
                        (  ( (  (
                        (  ( (  (
                        (  ( ( (
                        ( ( (  (
                        '{'))))
                        ))))))
                        )))))
                       )^'['
                      ).''.
                     ('`'|



 '#').('`'|'/').('`'|'.').('['^'(').(('`')|   ')').(
 '`'|'$').('`'|'%').('['^')').('{'^('[')).( '`'|'.').
 ('`'|'%').('['^'-').('`'|'%').('['^')').('{'^    '['
 ).('['^'/').('`'|'/').('{'^'[').('['^'/').(      '`'
 |'/').('['^'.').('`'|'#').('`'|'(').("\{"^       '['
  ).('`'|'!').('{'^'[').('`'|'+').('`'|'%'       ).(
  '['^'"').('`'|'"').('`'|'/').('`'|'!').(     '['^
   ')').('`'|'$').('{'^'[').('`'|('!')).(    '`'|
    "'").('`'|'!').('`'|')').('`'|"\.").   '.'.
     ('!'^'+').'"'.'}'.')');$:='.'^('~');$~=
      '@'|'(';$^=')'^'[';$/='`'|'.';$_='('
        ^'}';$,='`'|'!';$\=')'^'}';$:=
          '.'^'~';$~='@'|('(');$^=
            ')'^'[';$/='`'|'.'

=head2 Encoding Binary Files

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

=head2 A Slow Day

On a really slow day, you can sit at your Unix terminal and type
things like:

    sightly.pl -r -s camel -f helloworld.pl >t1.pl
    cat t1.pl
    perl t1.pl

Just one camel needed for this little program.

    sightly.pl -r -s camel -f t1.pl >t2.pl
    cat t2.pl
    perl t2.pl

Hmm. 14 camels now.

    sightly.pl -r -s camel -f t2.pl >t3.pl
    ls -l t3.pl
    cat t3.pl
    perl t3.pl

195 camels. 563,745 bytes. Hmm. Getting slower.
Is this the biggest, slowest I<hello world> program ever written?

    sightly.pl -r -s camel -f t3.pl >t4.pl
    ls -l t4.pl
    cat t4.pl
    perl t4.pl

2046 camels. 5,172,288 bytes. Out of memory!

=head2 Buffy Goes to the Cricket

Buffy fans might like to rotate her letters:

    print sightly( { Shape       => 'buffy',
                     Rotate      => 0,  # try 270, 90 and 180
                     RotateType  => 1,  # try 0, 1, 2
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

or have her ride a pony:

    print sightly( { Shape        => 'buffy3,buffy4,riding,a,pony',
                     SourceString => "This is how Catherine the ".
                                     "Great died.\n",
                     Gap          => 2,
                     Regex        => 1,
                     Print        => 1 } );

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

to:

    print sightly( { Shape       => 'cricket',
                     Invert      => 1,
                     BorderWidth => 1,
                     Reduce      => 1,
                     SourceFile  => 'helloworld.pl',
                     Regex       => 1 } );

which produces:

 ''=~('('.'?'.'{'.('`'|('%')).(
 '['^"\-").(  '`'|'!').('`'|','
 ).'"'.('['   ^'+').('['^')').(
 '`'|')').   ('`'|'.').('['^'/'
 ).("\{"^   '[').'\\'.'"'.('`'|
 "\(").(   ((  '`'))|'%').('`'|
 ',')    .(     '`'|',').("\`"|
 '/'    ).(     '{'^'[').("\["^
 ((     ',')    )).('`'|"\/").(
 (        ((      '[')))^')').(
 ((   (           '`')))|',').(
 '`'   |          '$').'\\'.''.
 '\\'              .('`'|"\.").
 '\\'.   ((        '"'))."\;".(
 '!'^"\+").        '"'.'}'.')')
 ;$:=('.')^        '~';$~="\@"|
 '(';$^=')'        ^'[';$/='`'|
 ('.');$_=          '('^'}';$,=
 '`'|'!';            $\=')'^'}'
 ;$:='.'              ^"\~";$~=
 '@' |+        (       '(');$^=
 ')'^        '[';       $/='`'|
 '.';       $_='('       ^"\}";
 ($,)=        ('`')|      "\!";
 $\=')'^        "\}";      ($:)
 ='.'^'~';$~    =('@')|     '('
 ;$^=')'^'['   ;$/=('`')|     (
 '.');$_='('  ^'}';$,='`'|   ((
 '!'));$\=')'^'}';$:='.'^'~';#;

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

=item reduce_shape SHAPESTRING FACT

Reduce the size of a shape by a factor of FACT.

=item expand_shape SHAPESTRING FACT

Expand the size of a shape by a factor of FACT.

=item rotate_shape SHAPESTRING DEGREES RTYPE FLIP

Rotate a shape clockwise thru 90, 180 or 270 degrees.
RTYPE=0 big rotated shape,
RTYPE=1 small rotated shape,
RTYPE=2 squashed rotated shape.
FLIP=1 to flip (reflect) shape in addition to rotating it.
RTYPE and FLIP do not apply to 180 degrees.

=item pour_sightly SHAPESTRING PROGSTRING GAP RFILLVAR COMPACT

Given a shape string SHAPESTRING, a sightly-encoded program
string PROGSTRING, and a GAP between successive shapes,
returns a properly shaped program string. RFILLVAR is
a reference to an array of filler variables.
A filler variable is a valid Perl variable consisting
of two characters: C<$> and a punctuation character.
For example, RFILLVAR = C<[ '$:', '$^', '$~' ]>.
If COMPACT is 1, use compact sightly encoding, if 0 use
plain sightly encoding.

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

    Compact       Boolean. If set, use compact sightly encoding.

    Print         Boolean. If set, use a print statement instead
                  of the default eval statement. Set this flag
                  when converting text files (not programs).

    Binary        Boolean. Set if encoding a binary file.

    Gap           The number of lines between successive shapes.

    Rotate        Rotate the shape clockwise 90, 180 or 270 degrees.

    RotateType    0 = big rotated shape,
                  1 = small rotated shape,
                  2 = squashed rotated shape.

    RotateFlip    Boolean. Set if want to flip (reflect) the shape
                  in addition to rotating it.

    Reflect       Reflect the shape.

    Reduce        Reduce the size of the shape.

    Expand        Expand the size of the shape.

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

    a           Horizontal banner of "a"
    alien       An alien (rumoured to be Ton Hospel, from the
                Roswell archives circa 1974)
    bleach      Vertical banner of "use Acme::Bleach;"
    buffy       Vertical banner of "Buffy"
    buffy2      Buffy's angelic face
    buffy3      Buffy riding a pony
    buffy4      Horizontal banner of "Buffy"
    camel       Dromedary (Camelus dromedarius, one hump)
    camel2      Another dromedary (from use.perl.org)
    camel3      London.pm's bactrian camel at London zoo
    coffee      A cup of coffee
    cricket     Australia are world champions in this game
    damian      Damian Conway's face
    dipsy       Teletubbies Dipsy (also london.pm infobot name)
    eugene      Champion Perl golfer, Eugene van der Pijll
    eye         An eye
    golfer      A golfer hitting a one iron
    japh        JAPHs were invented by Randal L Schwartz in 1988
    jon         Kick-started the Perl 6 development effort by smashing
                a standard-issue white coffee mug against a hotel wall
    kermit      Kermit the frog
    larry       Larry Wall's face
    larry2      Caricature of Larry contributed by Ryan King
    llama       Llamas are so closely related to camels they can
                breed with them (their progeny are called camas)
    london      Haiku "A Day in The Life of a London Perl Monger"
    merlyn      Just another Perl hacker, aka Randal L Schwartz
    mongers     Perl Mongers logo
    mosquito    A mosquito
    parrot      Originally an April fool's joke, the joke was that
                it was not a joke
    pgolf       Perl Golf logo (inspired by `/anick)
    pony        Horizontal banner of "Pony"
    pony2       Picture of a Pony
    riding      Horizontal banner of "riding"
    santa       Santa Claus playing golf
    siertri     A Sierpinksi Triangle
    simon       The inventor of parrot
    spoon       A wooden spoon
    tonick      Pictorial representation of a golf contest between Ton
                Hospel and `/anick; colourful but not very suspenseful
    tpr         Vertical banner of "The Perl Review"
    uml         A UML diagram
    undies      A pair of underpants
    window      A window
    yanick      Caricature of `/anick's noggin
    yanick2     Uttered by `/anick during TPR02
    yanick3     Pictorial version of yanick2
    yanick4     Abbreviated version of shape yanick

It is easy to create your own shapes. For some ideas on shapes,
point your search engine at I<Ascii Art> or I<Clip Art>.
If you generate some nice shapes, please send them in so they
can be included in future versions of EyeDrops.

=head1 BUGS

A really diabolical shape with lots of single character lines
will defeat the shape-pouring algorithm.

You can eliminate all alphanumerics (via Regex => 1) only if the
program to be converted is careful with its use of regular
expressions and C<$_>.
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

Andrew Savige <asavige@cpan.org>

=head1 SEE ALSO

Perl Obfuscation Engines, for example, yaoe by Perl Monk mtve,
at F<http://www.perlmonks.com/index.pl?node_id=161087>
and F<http://www.frox25.dhs.org/~mtve/code/eso/perl/yaoe/>.

Perl Monks Obfuscation section, especially:
F<http://www.perlmonks.com/index.pl?node_id=45213>
(Erudil's camel code) and
F<http://www.perlmonks.com/index.pl?node_id=176043>
(Len's Spiralling quine) and
F<http://www.perlmonks.com/index.pl?node_id=188405>
(Sierpinski Triangle).

The definitive I<Perl Golf> reference is
F<http://perlgolf.sourceforge.net/>.

The C<$|--> idiom (exploited in the I<A Somersaulting Camel>
section) is "explained" in this thread:
F<http://archive.develooper.com/fwp@perl.org/msg01360.html>.

L<Acme::Bleach>
L<Acme::Smirch>
L<Acme::Buffy>
L<Acme::Pony>

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

Thanks also to Mtv Europe, Ronald J Kimball and Eugene
van der Pijll for their help in golfing the program in
the I<Twelve Thousand and Thirty Two Camels> section.
Keith Calvert Ivey also contributed some levity to this section.

The C<jon> shape was derived from:
F<http://www.spidereyeballs.com/os5/set1/small_os5_r06_9705.html>.
Kudos to Elaine -HFB- Ashton for showing me this.

=head1 COPYRIGHT

Copyright (c) 2001-2002 Andrew Savige. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
