use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Graphics;
use PDF::Graphics::Text::Block;
use PDF::Graphics::Font;

plan 1;

my $font = PDF::Graphics::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $text = "Hello. Ting, ting, ting. Attention! … ATTENTION!";
my $text-block = PDF::Graphics::Text::Block.new( :$text, :$font, :font-key<Ft1>, :$font-size );

my $gfx = PDF::Graphics.new;

$gfx.print( $text-block );

is-json-equiv [ $gfx.ops ], [ :BT[],
                              :Tf[:name<Ft1>, :real(16)],
                              :TL[:real(17.6)],
                              :TJ[ :array[:literal("Hello. Ting, ting, ting. Attention! \x[85] ATTENTION!")] ],
                              :ET[],
    ], 'simple text block';
