#!/usr/bin/perl
# 00_Coffee.t (was convert.t)

use strict;
use Acme::EyeDrops qw(ascii_to_sightly sightly_to_ascii
                      get_eye_string make_siertri make_triangle
                      pour_sightly);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

print "1..16\n";

my $t1 = 'abcdefghijklmnopqrstuvwxyz';
my $f1 = ascii_to_sightly($t1);
# There are 32 characters in the sightly character set, namely:
# 33-47 (15), 58-64 (7), 91-96 (6), 123-126 (4).
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 1\n";

my $t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 2\n";

$t1 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 3\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 4\n";

$t1 = '0123456789';
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 5\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 6\n";

$t1 = "\n";
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 7\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 8\n";

$t1 = join("", map(chr, 0..255));
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 9\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 10\n";

# --------------------------------------------------

my $last_bit = <<'LAST_CAMEL';
                                      ############
           ######                   ###############
        ##########                ##################
 ##########  ######              ###################
LAST_CAMEL

my $camelstr = get_eye_string('camel');
$t1 = join("", map(chr, 0..255));
$f1 = ascii_to_sightly($t1);
my $shape = pour_sightly($camelstr, $f1, 0, "", 0, sub {});
$t1a = sightly_to_ascii($shape);
$t1 eq $t1a or print "not ";
print "ok 11\n";

$shape =~ tr/!-~/#/;
$shape eq $camelstr x 4 . $last_bit or print "not ";
print "ok 12\n";

my $siertristr = make_siertri(5);
$t1 = 'ABCDEFGHIJKLMNOPQ';
$f1 = ascii_to_sightly($t1);
$shape = pour_sightly($siertristr, $f1, 0, '#', 0, sub {});
$t1a = sightly_to_ascii($shape);
$t1 eq $t1a or print "not ";
print "ok 13\n";

$shape =~ tr/!-~/#/;
$shape eq $siertristr or print "not ";
print "ok 14\n";

my $trianglestr = make_triangle(42);
$t1 = 'abcdefghijklmnopqrstuvwxyz0123456789';
$f1 = ascii_to_sightly($t1);
$shape = pour_sightly($trianglestr, $f1, 0, '#', 0, sub {});
$t1a = sightly_to_ascii($shape);
$t1 eq $t1a or print "not ";
print "ok 15\n";

$shape =~ tr/!-~/#/;
$shape eq $trianglestr or print "not ";
print "ok 16\n";

exit 0;
