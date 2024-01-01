use v6;
use Test;
plan 3;
use lib 't';
use PDFTiny;
use PDF::Content;
use PDF::Content::Page;
use PDF::Content::Ops :OpCode;
use PDF::Content::FontObj;

my PDFTiny $pdf .= new;
my PDF::Content::Page $page = $pdf.add-page;
my PDF::Content $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my PDF::Content::FontObj $bold-font = $pdf.core-font( :family<Helvetica>, :weight<bold> );
my PDF::Content::FontObj $font = $pdf.core-font( :family<Helvetica> );

$gfx.say('Hello, World!', :$width, :kern, :position[50, 100], :font($bold-font), :$font-size);

is-deeply $gfx.content-dump, $(
    "BT",
    "1 0 0 1 50 100 Tm",
    "/F1 18 Tf",
    "(Hello,) Tj",
    "19.8 TL",
    "T*",
    "[ (W) 60 (orld!) ] TJ",
    "T*",
    "ET",
     ), "hello world (with kerning)";

$gfx.say('RVX', :$width, :shape, :position[150, 100], :font($bold-font), :$font-size);

is-deeply $gfx.content-dump.tail(5), $(
    "BT",
    "1 0 0 1 150 100 Tm",
    "[ (R) 50 (VX) ] TJ",
    "T*",
    "ET",
     ), "shaping";

$width = 100;
my $height = 150;
my $x = 20;
my $y = 700;

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

    $gfx.say("*** {%opts} *** " ~ $sample, :$width, :$height, :position[$x, $y], |%opts);

    if $x < 400 {
        $x += 110;
    }
    else {
        $y -= 170;
        $x = 20;
    }
}

$gfx.EndText;

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as('t/pdf-text-style.pdf');}

done-testing;
