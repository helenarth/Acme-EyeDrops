use strict;
use Acme::EyeDrops qw(get_eye_string get_eye_shapes
                      make_triangle make_siertri make_banner
                      border_shape invert_shape reflect_shape
                      hjoin_shapes sightly
                      reduce_shape expand_shape rotate_shape);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# A valid shape should:
#  1) contain only ' ' '#' and "\n"
#  2) be left-justified
#  3) no line should contain trailing spaces
#  4) be properly newline-terminated
#  5) contain no leading or trailing newlines
# This test verifies that is the case for all .eye shapes
# and for all subroutines that generate shapes.

# --------------------------------------------------

# make_banner is linux only (also requires /usr/games/banner executable)
my $have_banner = $^O eq 'linux' && -x '/usr/games/banner';

my @eye_shapes = get_eye_shapes();
my $n_tests = @eye_shapes * 6 + 12 * 6;
$n_tests += 6 if $have_banner;

print "1..$n_tests\n";

my $i = 0;

sub test_one_shape {
   my ($e, $s) = @_;
   $s =~ tr/ #\n//c and print "not ";
   ++$i; print "ok $i - $e valid chars\n";
   $s =~ /^#/m or print "not ";
   ++$i; print "ok $i - $e left justified\n";
   $s =~ / +$/m and print "not ";
   ++$i; print "ok $i - $e trailing spaces\n";
   substr($s, 0, 1) eq "\n" and print "not ";
   ++$i; print "ok $i - $e leading blank lines\n";
   substr($s, -1, 1) eq "\n" or print "not ";
   ++$i; print "ok $i - $e trailing blank lines\n";
   substr($s, -2, 1) eq "\n" and print "not ";
   ++$i; print "ok $i - $e properly newline terminated\n";
}

for my $e (@eye_shapes) { test_one_shape($e, get_eye_string($e)) }
my $s = get_eye_string('camel');
test_one_shape('border_shape', border_shape($s, 1, 1, 1, 1, 1, 1, 1, 1));
test_one_shape('invert_shape', invert_shape($s));
test_one_shape('reflect_shape', reflect_shape($s));
test_one_shape('hjoin_shapes', hjoin_shapes(3, $s, $s));
test_one_shape('reduce_shape', reduce_shape($s, 1));
test_one_shape('expand_shape', expand_shape($s, 1));
test_one_shape('rotate_shape-90', rotate_shape($s, 90, 0, 0));
test_one_shape('rotate_shape-180', rotate_shape($s, 180, 0, 0));
test_one_shape('rotate_shape-270', rotate_shape($s, 270, 0, 0));
test_one_shape('make_triangle', make_triangle(70));
test_one_shape('make_siertri', make_siertri(5));
my $p = sightly( { SourceString  => "knob\n",
                   Print         => 1,
                   Regex         => 1,
                   Shape         => 'camel,mongers',
                   Gap           => 3 } );
$p =~ tr/!-~/#/;
test_one_shape('multiple_shapes', $p);
test_one_shape('make_banner', make_banner(70, "a bc")) if $have_banner;

exit 0;
