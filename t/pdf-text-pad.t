use v6;
use Test;
plan 1;
use lib 't';
use PDF::Content;
use PDF::Content::Color :&color;
use PDF::Content::Ops :OpCode;
use PDF::Content::FontObj;
use PDF::Content::Page;
use PDFTiny;

sub draw-rect($gfx, @rect) {
    $gfx.tag: 'Artifact', {
        $gfx.StrokeAlpha = .5;
        $gfx.StrokeColor = color .5, .01, .01;
        $gfx.paint: :stroke, { .Rectangle(@rect[0], @rect[1], @rect[2] - @rect[0], @rect[3] - @rect[1]); }
    }
}

sub draw-cross($gfx, $x, $y) {
    $gfx.tag: 'Artifact', {
        $gfx.StrokeAlpha = .75;
        $gfx.StrokeColor = color .01, .7, 0.1;
        $gfx.paint: :stroke, { .MoveTo($x-5, $y);  .LineTo($x+5, $y); }
        $gfx.paint: :stroke, { .MoveTo($x, $y-5);  .LineTo($x, $y+5); }
    }
}

my PDFTiny $pdf .= new;
my PDF::Content::Page $page = $pdf.add-page;
my PDF::Content $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my PDF::Content::FontObj $font = $pdf.core-font( :family<Helvetica> );

$width = 100;
my $x = 50;

$gfx.Save;
$gfx.StrokeAlpha = .5;
$gfx.StrokeColor = color .5, .01, .01;
$gfx.set-font( $font, 10);

my $sample = q:to"--ENOUGH!!--".chomp;
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
ut labore et dolore magna aliqua.
--ENOUGH!!--

for 0, -5, 5 -> $pad-top {

    my $y = 700;
    for 0, -5, 5 -> $pad-left {
        my @rect[4];
        $gfx.&draw-cross($x, $y);
        $gfx.text: {
            .text-position = ($x, $y);
            @rect = .print: "*** pad-top:$pad-top pad-left:$pad-left *** " ~ $sample, :$width, :$pad-left, :$pad-top;
        }
        draw-rect $gfx, @rect;

        $y -= 100;
    }

   $x += 125;
}

$x = 50;

for 0, -5, 5 -> $pad-bottom {

    my $y = 350;
    for 0, -5, 5 -> $pad-right {
        my @rect[4];
        $gfx.&draw-cross($x, $y);
        $gfx.text: {
            .text-position = ($x, $y);
            @rect = .print: "*** pad-bottom:$pad-bottom pad-right:$pad-right *** " ~ $sample, :$width, :$pad-right, :$pad-bottom;
        }
        draw-rect $gfx, @rect;

        $y -= 100;
    }

   $x += 125;
}

$gfx.Restore;

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-pad.pdf')};

done-testing;
