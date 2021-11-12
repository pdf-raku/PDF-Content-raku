use v6;
use Test;
plan 1;
use lib 't';
use PDF::Content;
use PDF::Content::Ops :OpCode;
use PDF::Content::FontObj;
use PDF::Content::Page;
use PDFTiny;

my PDFTiny $pdf .= new;
my PDF::Content::Page $page = $pdf.add-page;
my PDF::Content $gfx = $page.gfx;
my $width = 50;
my $font-size = 18;

my PDF::Content::FontObj $font = $page.core-font( :family<Helvetica> );

$width = 100;
my $height = 80;
my $x = 110;

$gfx.BeginText;
$gfx.set-font( $font, 10);

my $sample = q:to"--ENOUGH!!--";
First Line
 Line2, leading space
Wrapping text follows...
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
last line
--ENOUGH!!--

my $baseline = 'top';

for False, True -> $verbatum {
    for True, False -> $chomp {

        my $y = 700;

        for <left center right justify> -> $align {
            $gfx.text-position = ($x, $y);
            my $text = "*** verbatum:$verbatum chomp:$chomp $align *** " ~ $sample;
            $text .= chomp if $chomp;
            $gfx.say($text, :$width, :$height, :$verbatum, :$align, :$baseline );
            $y -= 120;
        }

        $x += 125;
    }
}
$gfx.EndText;

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-verbatum.pdf')};

done-testing;
