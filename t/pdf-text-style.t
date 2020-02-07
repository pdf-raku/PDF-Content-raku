use v6;
use Test;
plan 2;
use lib 't/lib';
use PDF;
use PDF::Content::Ops :OpCode;
use PDFTiny;
# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;
my $page = $pdf.add-page;
my $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my $bold-font = $page.core-font( :family<Helvetica>, :weight<bold> );
my $font = $page.core-font( :family<Helvetica> );

$gfx.tag: 'P', {
    .text: {
        .text-position = 50, 100;
        .font = $bold-font, $font-size;
        .say('Hello, World!', :$width, :kern);
    }
};

todo "needs PDF >= v0.4.1"
   unless PDF.^ver >= v0.4.1;
is-deeply $gfx.content-dump, $(
    "/P << /MCID 0 >> BDC",
    "BT",
    "1 0 0 1 50 100 Tm", 
    "/F1 18 Tf",
    "(Hello,) Tj",
    "19.8 TL",
    "T*",
    "[ (W) 60 (orld!) ] TJ",
    "T*",
    "ET",
    "EMC",
    ), "hello world (with kerning)";

$width = 100;
my $height = 150;
my $x = 20;
my $y = 700;

$gfx = $page.gfx;

my $sample = q:to"--ENOUGH!!--";
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat.  Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur.  ut labore et dolore magna aliqua.
--ENOUGH!!--

$gfx.BeginText;
$gfx.set-font($font, 10);
my %default-settings = :TextRise(0), :HorizScaling(100), :CharSpacing(0), :WordSpacing(0);

for (
    :TextRise(0), :TextRise(3), :TextRise(-3),
    :HorizScaling(75), :HorizScaling(150),
    :CharSpacing(-.75), :CharSpacing(.75), :CharSpacing(1.5),
    :WordSpacing(-2), :WordSpacing(5),
    :leading(.8), :leading(1.5),
    :baseline<top>,
    ) {
    my %opts = %default-settings;
    %opts{.key} = .value;

    for %opts.keys {
	if $_ ~~ /^[A..Z]/
        && $_ ne 'CharSpacing'|'WordSpacing'|'HorizScaling'|'TextRise' {
            $gfx."$_"() = %opts{$_};
        }

        if %default-settings{$_}:exists {
            %opts{$_}:delete
                if %opts{$_} == %default-settings{$_}
        }
    }

    $gfx.text-position = ($x, $y);
    $gfx.say("*** {%opts} *** " ~ $sample, :$width, :$height, |%opts);

    if $x < 400 {
        $x += 110;
    }
    else {
        $y -= 170;
        $x = 20;
    }
}

$gfx.EndText;

is $page.new-tags.map(*.gist).join, '<P MCID="0"/>', '.new-tags()';

$pdf.save-as('t/pdf-text-style.pdf');

done-testing;
