use v6;
use Test;
plan 3;
use lib '.';
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

my $text-block;

$page.text: -> $gfx {
    $gfx.text-position = [100, 500];
    $text-block = $gfx.text-block( :@chunks, :$font, :$font-size, :width(220) );
    $gfx.say($text-block);
    my $unreplaced-width  = $text-block.content-width;
    my $unreplaced-height = $text-block.content-height;
    for @chunks.grep('the'|'aga') -> $source is rw {
        my $width = $font.stringwidth($source, $font-size);
        my $height = 1;
        $source = PDF::Content::Replaced.new: :$width, :$height, :$source;
    }
    $text-block = $gfx.text-block( :@chunks, :$font, :$font-size, :width(220) );
    $gfx.say($text-block);
    is-approx $text-block.content-width, $unreplaced-width, '$.content-width';
    is-approx $text-block.content-height, $unreplaced-height, '$.content-height';

    is-json-equiv $text-block.replaced, [
        {:Tm[1, 0, 0, 1, 241.344, 464.8], :Tx(141.344), :Ty(<0/1>), :source("the")},
        {:Tm[1, 0, 0, 1, 100.0, 447.2], :Tx(0.0), :Ty(-17.6), :source("aga")}
    ], 'replacements';
}

replace-text($page, $text-block);

sub replace-text($page, $text-block) {
    # put the replaced words back; in color
    $page.graphics: -> $gfx {
        $gfx.FillColor = :DeviceRGB[.9, .4, .4];
        $page.text: {
            for $text-block.replaced {
                $gfx.TextMatrix = .<Tm>;
                $gfx.print(.<source>, :$font, :$font-size);
            }
        }
    }
}

$page.graphics: -> $gfx {
    my $text = q:to<END-QUOTE>;
    To be, or not to be, that is the question:
    Whether 'tis nobler in the mind to suffer
    The slings and arrows of outrageous fortune,
    Or to take Arms against a Sea of troubles,
    And by opposing end them: to die, to sleep
    No more; and by a sleep, to say we end
    the heart-ache, and the thousand natural shocks
    that Flesh is heir to? 'Tis a consummation
    devoutly to be wished.
    END-QUOTE

    my @chunks = PDF::Content::Text::Block.comb($text);
    for @chunks.grep('the') -> $source is rw {
        my $width = $font.stringwidth($source, $font-size);
        my $height = $font-size * 1.5;
        $source = PDF::Content::Replaced.new: :$width, :$height, :$source;
    }
    $text-block = $gfx.text-block( :@chunks, :$font, :$font-size, :width(250) );
    $page.text: {
        $gfx.print($text-block, :position[100, 400]);
    }
    replace-text($page, $text-block);
 }

$pdf.save-as: "t/text-replaced.pdf";
