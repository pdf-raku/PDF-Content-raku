use v6;
use Test;
plan 1;
use lib 't';
use PDF::Content::Ops :OpCode;
use PDF::Content::FontObj;
use PDFTiny;

my PDFTiny $pdf .= new;
my $page = $pdf.add-page;
my $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my PDF::Content::FontObj $font = $page.core-font( :family<Helvetica> );

$width = 100;
my $height = 80;
my $x = 110;

$gfx.BeginText;
$gfx.set-font( $font, 10);

my $sample = q:to"--ENOUGH!!--";
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
ut labore et dolore magna aliqua.
--ENOUGH!!--

my $baseline = 'top';

for <top center bottom> -> $valign {

    my $y = 700;

    for <left center right justify> -> $align {
        $gfx.text-position = ($x, $y);
        $gfx.say( "*** $valign $align*** " ~ $sample, :$width, :$height, :$valign, :$align, :$baseline );
        $y -= 170;
    }

   $x += 125;
}
$gfx.EndText;

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-align.pdf')};

done-testing;
