#!/usr/bin/perl
# examples.pl. Some example sightly calls.

use strict;
use Acme::EyeDrops qw(sightly);

# This writes to STDOUT a Perl program equivalent to the original
# helloworld.pl, but prettier, and shaped like a camel.
print sightly({ Shape       => 'camel',
                SourceFile  => 'helloworld.pl' } );

my $src = <<'PROG';
open 0;
$/ = undef;
$x = <0>;
close 0;
$x =~ tr/!-~/#/;
print $x;
PROG

# This writes to STDOUT a self-printing JAPH (program $src).
# print sightly({ Shape         => 'japh',
#                 SourceString  => $src } );

# Same thing, but this time with no alphanumeric characters.
# This is achieved by embedding the program inside a regex.
# This works here because selfprint.pl contains no regexs.
# It will fail for more complex programs because Perl's
# regex engine is not reentrant.
# print sightly({ Shape         => 'japh',
#                 SourceString  => $src,
#                 Regex         => 1 } );

# An example Windows program.
# print sightly({ Shape         => 'window',
#                 SourceString  => "Bill Gates is a pest!\n",
#                 Regex         => 1,
#                 Print         => 1 } );

# This shows how to sightly-encode a binary file.
# To decode, run the generated Perl program, redirecting STDOUT.
# print sightly({ Shape       => 'camel,japh,camel',
#                 SourceFile  => 'sightly.pl',
#                 Binary      => 1,
#                 Print       => 1,
#                 Gap         => 5 } );

# This example works on Linux only.
# It uses /usr/games/banner to pour the original program into
# a banner of itself.
# print sightly({ Shape       => 'srcbanner',
#                 SourceFile  => 'helloworld.pl' } );
