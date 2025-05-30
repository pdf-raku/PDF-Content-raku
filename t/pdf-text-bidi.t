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
constant $LRO = "\c[LEFT-TO-RIGHT OVERRIDE]";
constant $RLO = "\c[RIGHT-TO-LEFT OVERRIDE]";
constant $PDF = "\c[POP DIRECTIONAL FORMATTING]";

if (try require ::('Text::FriBidi::Lines')) === Nil {
    skip-rest "Text::FriBidi v0.0.4+ is required for :bidi tests";
    exit 0;
}

my $text = "Left {$RLO}Right{$PDF} {$LRO}left{$PDF}";

my PDF::Content::FontObj $font = $pdf.core-font( :family<Helvetica> );

$gfx.BeginText;
$gfx.set-font( $font, 10);

$gfx.text-position = 110, 500;
$gfx.say: $text, :!bidi;
$gfx.say: $text;
$gfx.say: $text, :width(15);

$gfx.EndText;

# ensure consistant document ID generation
$pdf.id = $*PROGRAM.basename.fmt('%-16.16s');

lives-ok {$pdf.save-as('t/pdf-text-bidi.pdf')};

done-testing;
