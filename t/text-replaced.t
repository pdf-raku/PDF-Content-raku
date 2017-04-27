use v6;
use Test;
plan 4;
use lib '.';
use PDF; # give rakudo a hand loading PDF::Lite
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Text::Block;
use PDF::Content::Util::Font;
use PDF::Content::Replaced;
use t::PDFTiny;

# ensure consistant document ID generation
srand(123456);

my $pdf = t::PDFTiny.new;
my $page = $pdf.add-page;

my @chunks = PDF::Content::Text::Block.comb: 'I must go down to the seas';
@chunks.append: ' ', 'aga','in';
my $font = PDF::Content::Util::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;

my $text-block = PDF::Content::Text::Block.new( :@chunks, :$font, :$font-size );

constant TextPos = [100, 350];

$page.text: -> $gfx {
    $gfx.text-position = TextPos;
    $gfx.say: $text-block;
    my $unreplaced-width  = $text-block.content-width;
    my $unreplaced-height = $text-block.content-height;
    for @chunks.grep('the'|'aga') -> $source is rw {
        my $width = $font.stringwidth($source, $font-size);
        my $height = $font.height($font-size);
        $source = PDF::Content::Replaced.new: :$width, :$height, :$source;
    }
    $text-block = PDF::Content::Text::Block.new( :@chunks, :$font, :$font-size );
    is-approx $text-block.content-width, $unreplaced-width, '$.content-width';
    is-approx $text-block.content-height, $unreplaced-height, '$.content-height';
    $gfx.say( $text-block );

    is-json-equiv [ $gfx.ops ], [
        :BT[],
        :Tm[ :real(1),   :real(0),
             :real(0),   :real(1),
             :real(100), :real(350), ],
        :Tf[:name<F1>,   :real(16)],
        :TL[:real(17.6)],
        :Tj[ :literal("I must go down to the seas again")],
        'T*' => [],
        :TL[ :real(17.6) ],
        :TJ[
            :array[
                     :literal("I must go down to "),
                     :int(-1500),
                     :literal(" seas "),
                     :int(-1723),
                     :literal("in"),
                 ]
             ],
        'T*' => [],
    ], 'simple replaced text block';

    is-deeply $text-block.replaced, [
        {:source("the"), :bottom(-17.6), :left(141.344), :offset[0.0, 0.0]},
        {:source("aga"), :bottom(-17.6), :left(209.824), :offset[0.0, 0.0]},
    ], 'replacements';

}

$page.graphics: -> $gfx {
    # put the replaced words back; in color
    $gfx.FillColor = :DeviceRGB[.9, .4, .4];
    $page.text: {
        for $text-block.replaced {
            $gfx.text-position = [TextPos[0] + .<offset>[0] + .<left>[0], TextPos[1] + .<offset>[1] + .<bottom>];
            $gfx.print(.<source>, :$font, :$font-size);
        }
    }
}

$pdf.save-as: "t/text-replaced.pdf";
