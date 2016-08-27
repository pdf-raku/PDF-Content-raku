use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::PDF;
use PDF::Content::Text::Block;
use PDF::Content::Util::Font;

plan 3;

my $font = PDF::Content::Util::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $text = "Hello. Ting, ting, ting. Attention! … ATTENTION!";
my $pdf = PDF::Content::PDF.new;
my $text-block = PDF::Content::Text::Block.new( :$text, :$font, :$font-size );
is-approx $text-block.actual-width, 364.448, '$.actual-width';
is-approx $text-block.actual-height, 19.04, '$.actual-height';
my $gfx = $pdf.add-page.gfx;
$gfx.Save;
$gfx.BeginText;
$gfx.text-position = [100, 350];
$gfx.say( $text-block );
# go bolder
$text-block.thickness += 5;
$gfx.print( $text-block );
$gfx.EndText;
$gfx.Restore;

is-json-equiv [ $gfx.ops ], [
    :q[],
    :BT[],
    :Tm[ :real(1),   :real(0),
         :real(0),   :real(1),
         :real(100), :real(350), ],
    :Tf[:name<F1>, :real(16)],
    :TL[:real(17.6)],
    :TJ[ :array[:literal("Hello. Ting, ting, ting. Attention! \x[85] ATTENTION!")] ],
    'T*' => [],
    :Tr[ :int(2) ],
    :w[ :real(0.3125) ],
    :TJ[ :array[:literal("Hello. Ting, ting, ting. Attention! \x[85] ATTENTION!")] ],
    :ET[],
    :Q[],
    ], 'simple text block';

$pdf.save-as: "t/text-block.pdf";
