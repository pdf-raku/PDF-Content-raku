use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::PDF;
use PDF::Content::Text::Block;
use PDF::Content::Util::Font;

plan 5;

# ensure consistant document ID generation
srand(123456);

my \nbsp = "\c[NO-BREAK SPACE]";
my @chunks = "z80 a-b.   {nbsp}A{nbsp}bc{nbsp} 42".comb: /<PDF::Content::Text::Block::Text::word> | <PDF::Content::Text::Block::Text::space> /;
is-deeply @chunks, ["z80", " ", "a-", "b.", "   ", "{nbsp}A{nbsp}bc{nbsp}", " ", "42"], ;

my $font = PDF::Content::Util::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $text = " Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my $pdf = PDF::Content::PDF.new;
my $text-block = PDF::Content::Text::Block.new( :$text, :$font, :$font-size );
is-approx $text-block.actual-width, 360.88, '$.actual-width';
is-approx $text-block.actual-height, 19.04, '$.actual-height';
my $gfx = $pdf.add-page.gfx;
$gfx.Save;
$gfx.BeginText;
$gfx.text-position = [100, 350];
is-deeply $gfx.text-position, (100, 350), 'text position';
$gfx.say( $text-block );
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
    :TJ[ :array[:literal("Hello. Ting, ting-ting. Attention! \x[85] ATTENTION!")] ],
    'T*' => [],
    :TJ[ :array[:literal("Hello. Ting, ting-ting. Attention! \x[85] ATTENTION!")] ],
    :ET[],
    :Q[],
    ], 'simple text block';

$pdf.save-as: "t/text-block.pdf";
