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

for 0, -5, 5 -> $border-top {

    my $y = 700;
    for 0, -5, 5 -> $border-left {
        my @rect[4];
        $gfx.&draw-cross($x, $y);
        $gfx.text: {
            .text-position = ($x, $y);
            @rect = .print: "*** border-top:$border-top border-left:$border-left *** " ~ $sample, :$width, :$border-left, :$border-top;
        }
        draw-rect $gfx, @rect;

        $y -= 100;
    }

   $x += 125;
}

$x = 50;

for 0, -5, 5 -> $border-bottom {

    my $y = 350;
    for 0, -5, 5 -> $border-right {
        my @rect[4];
        $gfx.&draw-cross($x, $y);
        $gfx.text: {
            .text-position = ($x, $y);
            @rect = .print: "*** border-bottom:$border-bottom border-right:$border-right *** " ~ $sample, :$width, :$border-right, :$border-bottom;
        }
        draw-rect $gfx, @rect;

        $y -= 100;
    }

   $x += 125;
}

$gfx.Restore;

$page = $pdf.add-page;
$gfx = $page.gfx;

my List @rects;

$gfx.text: {
    .text-position = 10, 750;
    .say: 'Text Flow Tests:';
    .say;
    .print: 'Baseline: ';
    for <alphabetic top bottom middle ideographic hanging> -> $baseline {
        @rects.push: .print: $baseline, :$baseline;
    }
    .text-position = 10, 620;
    .print: 'Valign: ';
    for <top center bottom top> -> $valign {
        @rects.push: .print: $valign, :$valign;
    }

    my $x = 150;
    my $y = 510;
    .text-position = 10, $y;
    .print: 'Valign wrapping: ';
    for <top center bottom top> -> $valign {
        $x += 65;
        .text-position = $x, $y;
        @rects.push: .print: "multi $valign lines", :$valign, :width(60);
    }

    $x = 150;
    $y = 350;
    .text-position = 10, $y;
    .print: 'Valign fixed height: ';
    for <top center bottom top> -> $valign {
        $x += 65;
        .text-position = $x, $y;
        @rects.push: .print: "$valign lines", :$valign, :width(60), :height(80);
    }

    $x = 180;
    $y = 250;
    .text-position = 10, $y;
    .print: 'align: ';
    for <right center left justify> -> $align {
        $x += 80;
        .text-position = $x, $y;
        @rects.push: .print: $align, :$align;
    }

    $x = 180;
    $y = 210;
    .text-position = 10, $y;
    .print: 'align fixed width: ';
    for <right center left justify> -> $align {
        $x += 80;
        .text-position = $x, $y;
        @rects.push: .print: $align, :$align, :width(70);
    }
}

$gfx.graphics: {
    draw-rect($gfx, $_) for @rects;
}

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-bbox.pdf')};

done-testing;
