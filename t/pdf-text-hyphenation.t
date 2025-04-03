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
my $x = 110;

$gfx.Save;
$gfx.StrokeAlpha = .5;
$gfx.StrokeColor = color .5, .01, .01;
$gfx.set-font( $font, 10);

my $hp = "\c[HYPHENATION POINT]";
my $sample = qq:to"--!END!--".chomp;
Lo{$hp}rem ip{$hp}sum do{$hp}lor sit a{$hp}met, con{$hp}sec{$hp}tet{$hp}ur
ad{$hp}ip{$hp}isc{$hp}ing e{$hp}lit, sed do ei{$hp}us{$hp}mod tem{$hp}por
in{$hp}ci{$hp}di{$hp}dunt ut la{$hp}bore et do{$hp}lore mag{$hp}na
a{$hp}li{$hp}qua
--!END!--

for <top center bottom> -> $valign {

    my $y = 700;
    for <left center right justify> -> $align {
        my @rect[4];
        $gfx.&draw-cross($x, $y);
        $gfx.text: {
            .text-position = ($x, $y);
            @rect = .print: "*** $valign $align *** " ~ $sample, :$width, :$valign, :$align;
        }
        draw-rect $gfx, @rect;

        $y -= 170;
    }

   $x += 125;
}

$gfx.Restore;

# ensure consistant document ID generation
$pdf.id = $*PROGRAM.basename.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-hyphenation.pdf')};

done-testing;
