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

my PDFTiny $pdf .= new;
my PDF::Content::Page $page = $pdf.add-page;
my PDF::Content $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my PDF::Content::FontObj $font = $pdf.core-font( :family<Helvetica> );

$width = 100;
my $height = 80;
my $x = 110;

$gfx.Save;
$gfx.StrokeAlpha = .5;
$gfx.StrokeColor = color .5, .01, .01;
$gfx.set-font( $font, 10);

sub draw-rect($gfx, @rect) {
    $gfx.tag: 'Artifact', {
        $gfx.StrokeAlpha = .5;
        $gfx.StrokeColor = color .5, .01, .01;
        $gfx.paint: :stroke, { .Rectangle(@rect[0], @rect[1], @rect[2] - @rect[0], @rect[3] - @rect[1]); }
    }
}

my $sample = q:to"--ENOUGH!!--".chomp;
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
ut labore et dolore magna aliqua.
--ENOUGH!!--

my $baseline = 'top';

for <top center bottom> -> $valign {

    my $y = 700;
    for <left center right justify> -> $align {
        my @rect[4];
        $gfx.text: {
            .text-position = ($x, $y);
            @rect= $gfx.say( "*** $valign $align*** " ~ $sample, :$width, :$height, :$valign, :$align, :$baseline );
        }
        draw-rect $gfx, @rect;

        $y -= 170;
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
    .text-position = 10, 650;
    .print: 'Valign: ';
    for <top center bottom top> -> $valign {
        @rects.push: .print: $valign, :$valign;
    }
}

$gfx.graphics: {
    draw-rect($gfx, $_) for @rects;
}

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-align.pdf')};

done-testing;
