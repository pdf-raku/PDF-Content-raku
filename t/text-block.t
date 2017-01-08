use v6;
use Test;
plan 5;
use lib '.';
use PDF; # give rakudo a hand loading PDF::Lite
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Text::Block;
use PDF::Content::Util::Font;
use t::PDFTiny;

# ensure consistant document ID generation
srand(123456);

my \nbsp = "\c[NO-BREAK SPACE]";
my @chunks = "z80 a-b. -3   {nbsp}A{nbsp}bc{nbsp} 42".comb: /<PDF::Content::Text::Block::Text::word> | <PDF::Content::Text::Block::Text::space> /;
is-deeply @chunks, ["z80", " ", "a-", "b.", " ", "-", "3", "   ", "{nbsp}A{nbsp}bc{nbsp}", " ", "42"], ;

my $font = PDF::Content::Util::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $text = " Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my $pdf = t::PDFTiny.new;
my $text-block = PDF::Content::Text::Block.new( :$text, :$font, :$font-size );
is-approx $text-block.content-width, 360.88, '$.content-width';
is-approx $text-block.content-height, 19.04, '$.content-height';
my $gfx = $pdf.add-page.gfx;
$gfx.Save;
$gfx.BeginText;
$gfx.text-position = [100, 350];
is-deeply $gfx.text-position, (100, 350), 'text position';
$gfx.say( $text-block );
$text-block.baseline = 'bottom';
$gfx.print( $text-block );
$gfx.EndText;
$gfx.Restore;

is-json-equiv [ $gfx.ops ], [
    :q[],
    :BT[],
    :Tm[ :real(1),   :real(0),
         :real(0),   :real(1),
         :real(100), :real(350), ],
    :Tf[:name<F1>,   :real(16)],
    :TL[:real(17.6)],
    :Tj[ :literal("Hello. Ting, ting-ting. Attention! \x[85] ATTENTION!")],
    'T*' => [],
    :Td[ :real(0), :real(3.648) ],
    :Tj[ :literal("Hello. Ting, ting-ting. Attention! \x[85] ATTENTION!")],
    :ET[],
    :Q[],
    ], 'simple text block';

$pdf.save-as: "t/text-block.pdf";
