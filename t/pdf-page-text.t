use v6;
use Test;
plan 1;
use PDF; # give rakudo a hand loading PDF::Lite
use PDF::Content::Ops :OpCode;

unless try {require PDF::Lite; 1} {
    skip-rest 'PDF::Lite is required to run tests';
    exit;
}
# ensure consistant document ID generation
srand(123456);

my $pdf = ::('PDF::Lite').new;
my $page = $pdf.add-page;
my $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my $bold-font = $page.core-font( :family<Helvetica>, :weight<bold> );
my $reg-font = $page.core-font( :family<Helvetica> );

$gfx.BeginText;
$gfx.TextMove(50,100);
$gfx.set-font($bold-font, $font-size);
$gfx.say('Hello, World!', :$width, :kern);
$gfx.EndText;

is-deeply $gfx.content-dump, $(
    "BT",
    "50 100 Td", 
    "/F1 18 Tf",
    "19.8 TL",
    "(Hello,) Tj",
    "T*",
    "[ (W) 60 (orld!) ] TJ",
    "T*",
    "ET");

$width = 100;
my $height = 80;
my $x = 110;

$gfx.BeginText;
$gfx.set-font( $reg-font, 10);

my $sample = q:to"--ENOUGH!!--";
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
ut labore et dolore magna aliqua.
--ENOUGH!!--

my $sample2 = q:to"--I-SAID, ENOUGH!!--";
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
ut labore et dolore magna aliqua.
--I-SAID, ENOUGH!!--

my $baseline = 'top';

for <top center bottom> -> $valign {

    my $y = 700;

    for <left center right justify> -> $align {
        $gfx.text-position = ($x, $y);
        $gfx.say( "*** $valign $align*** " ~ $sample, :$width, :$height, :$valign, :$align, :$baseline);
        $y -= 170;
    }

   $x += 125;
}
$gfx.EndText;

$page = $pdf.add-page;
$gfx = $page.gfx;

$height = 150;
$x = 20;
my $y = 700;

my $op-tab = OpCode.enums;

$gfx.BeginText;
$gfx.set-font($reg-font, 10);
my %default-settings = :TextRise(0), :HorizScaling(100), :CharSpacing(0), :WordSpacing(0);

for (
    :TextRise(0), :TextRise(3), :TextRise(-3),
    :HorizScaling(50), :HorizScaling(100), :HorizScaling(150),
    :CharSpacing(-1.0), :CharSpacing(-.5), :CharSpacing(.5), :CharSpacing(1.5),
    :WordSpacing(-2), :WordSpacing(5), :leading(8), :leading(15),
    :baseline<top>,
    ) {
    my %settings = %default-settings;
    %settings{.key} = .value;
    my %opts;

    for %settings.keys {
        if /^<[A..Z]>/ {
            $gfx."$_"() = %settings{$_};
            %settings{$_}:delete
                if %settings{$_} == %default-settings{$_}
        }
        else {
            %opts{$_} = %settings{$_};
        }
    }

    $gfx.text-position = ($x, $y);
    $gfx.say( ("*** {%settings} *** ", $sample, $sample2).join(' '), :$width, :$height, |%opts);

    if $x < 400 {
        $x += 110;
    }
    else {
        $y -= 170;
        $x = 20;
    }
}

$gfx.EndText;

$pdf.save-as('t/pdf-page-text.pdf');

done-testing;
