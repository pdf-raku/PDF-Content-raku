use v6;
use Test;
plan 3;
use lib 't';
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Text::Box;
use PDF::Content::Font::CoreFont;
use PDF::Content::Page;
use PDF::Content::XObject;
use PDFTiny;

# experimental feature to flow text and images

my PDFTiny $pdf .= new;
my PDF::Content::Page $page = $pdf.add-page;

my @chunks = PDF::Content::Text::Box.comb: 'I must go down to the seas';
@chunks.append: ' ', 'aga','in';
my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my PDF::Content::XObject $image .= open: "t/images/lightbulb.gif";

my $image-padded = $page.xobject-form(:BBox[0, 0, $image.width + 1, $image.height + 4]);
$image-padded.gfx;
my @rect;
$image-padded.graphics: {
    @rect = .do($image, :position[1,0]);
}
is-deeply @rect, [1, 0, 1 + $image.width, $image.height], '$gfx.do returned rectangle';

my $text-box;

$page.text: -> $gfx {
    $gfx.TextMove(100, 500);
    $text-box = $gfx.text-box( :@chunks, :$font, :$font-size, :width(220) );
    $gfx.say($text-box);
    for @chunks.grep('the'|'aga') -> $source is rw {
        $source = $image-padded;
    }
    $text-box = $gfx.text-box( :@chunks, :$font, :$font-size, :width(220) );
    @rect = $gfx.say($text-box).list;
    is-deeply [@rect.map(*.round)], [100, 465, 100+220, 465+50], '$gfx.say returned rectangle';

    is-json-equiv [$text-box.images.map({[ .<Tx>, .<Ty> ]})], [
        [141.344, 0],
        [0.0, -25.3]
    ], 'images';
}

$text-box.place-images($page.gfx);

$page.graphics: -> $gfx {
    $gfx.HorizScaling = 120;
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

    my @chunks = PDF::Content::Text::Box.comb($text);
    for @chunks.grep('the') -> $source is rw {
        my $width = $font.stringwidth($source, $font-size);
        my $height = $font-size * 1.5;
        $source = $image-padded;
    }
    $text-box = $gfx.text-box( :@chunks, :$font, :$font-size, :width(250) );
    $page.text: {
        $gfx.print($text-box, :position[100, 400]);
    }
}

$text-box.place-images($page.gfx);

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

$pdf.save-as: "t/text-box-images.pdf";
