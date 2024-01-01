use v6;
use Test;
plan 18;
use lib 't';
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Text::Box;
use PDF::Content::Font::CoreFont;
use PDF::Content::Color :color, :ColorName;
use PDFTiny;

my \nbsp = "\c[NO-BREAK SPACE]";
my @chunks =  PDF::Content::Text::Box.comb: "z80 a-b. -3   {nbsp}A{nbsp}bc{nbsp} 42";
is-deeply @chunks, ["z80", " ", "a-", "b.", " ", "-", "3", "   ", "{nbsp}A{nbsp}bc{nbsp}", " ", "42"], 'text-box comb';

my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $height = 20;
my $text = "Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my PDFTiny $pdf .= new;
my PDF::Content::Text::Box $text-box .= new( :$text, :$font, :$font-size, :$height );
is $text-box.text, $text;
is $text-box.font-size, 16;
is $text-box.height, 20;
is-approx $text-box.space-width, 4.448, 'space-width';
is-approx $text-box.content-width, 369.776, '$.content-width';
is-approx $text-box.content-height, 17.6, '$.content-height';
is +$text-box.lines, 1;

subtest 'text box cloning', {
    $text-box .= clone;
    is $text-box.text, $text, '$.text';
    is +$text-box.lines, 1, '$.lines';
    is-approx $text-box.content-width, 369.776, '$.content-width';
    is-approx $text-box.content-height, 17.6, '$.content-height';
    is $text-box.font-size, $font-size, '$.font-size';
    is-deeply $text-box.font, $font, '$.font';
    is $text-box.height, $height, '$.height';
    is $text-box.underline-position, -1.6;
    is $text-box.underline-thickness, 0.8;
    is $text-box.font-height, 19.04;
}

my $gfx = $pdf.add-page.gfx;
subtest 'text box rendering', {
    $gfx.Save;
    $gfx.BeginText;
    $gfx.text-position = [100, 350];
    $gfx.FillColor = color Blue;
    is-deeply $gfx.text-position, (100.0, 350.0), 'text position';
    $gfx.say( $text-box );
    is-deeply $gfx.text-position, (100.0, 350 - 17.6), 'text position';
    $text-box .= new( :$text, :$font, :$font-size, :squish );
    is-approx $text-box.content-width, 365.328, '$.content-width (squished)';
    is-approx $text-box.content-height, 17.6, '$.content-height (squished)';
    $text-box.TextRise = $text-box.baseline-shift('bottom');
    $gfx.print( $text-box, :!preserve );
    $gfx.EndText;
    $gfx.Restore;
}

$text-box .= clone: :width(250);
is +$text-box.width, 250, '$.clone with width constraint';
given $text-box.content-width {
    ok $_ <= 250, '$.clone content-width'
        or diag "content-width: $_ !<= 250"
}
is-approx $text-box.height, 35.2;
is +$text-box.lines, 2, '$.clone with width constraint';

subtest 'text updated', {
    $text-box.text = 'Hello!';
    is +$text-box.lines, 1, '$.lines';
    is-approx $text-box.content-width, 44.448, '$.content-width';
    is-approx $text-box.content-height, 17.6, '$.content-height';
    is $text-box.font-size, $font-size, '$.font-size';
    is-deeply $text-box.font, $font, '$.font';
    is $text-box.height, 17.6, '$.height';
}

is-json-equiv [ $gfx.ops ], [
    :q[],
      :BT[],
        :Tm[ 1, 0, 0, 1, 100, 350 ],
        :rg[ 0, 0, 1 ],
        :Tf[:name<F1>,   (16)],
        :Tj[ :literal("Hello.  Ting, ting-ting. Attention! \x[85] ATTENTION! ")],
        :TL[(17.6)],
        'T*' => [],
        :Ts[ 3.312 ],
        :Tj[ :literal("Hello. Ting, ting-ting. Attention! \x[85] ATTENTION! ")],
      :ET[],
    :Q[],
    ], 'simple text box';

subtest 'overflow', {
    $gfx.text: {
        $text = q:to<END>.chomp;
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        END
        my $width = 200;
        $height = 50;
        $text-box .= new( :$text, :$font, :$font-size, :$width, :$height );
        .text-position = 100, 500;
        .say: $text-box;
        is $text-box.lines[0].text, 'Lorem ipsum dolor sit';
        is $text-box.lines[1].text, 'amet, consectetur';
        is-deeply  $text-box.Str.lines, ('Lorem ipsum dolor sit', 'amet, consectetur');
        is $text-box.overflow.join, " elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
        $text = '...' ~ $text-box.overflow.join;
        $text-box .= clone: :$text;
        .say: $text-box;
        is $text-box.overflow.join, ' et dolore magna aliqua.';
        .say: '...' ~ $text-box.overflow.join;
    }
}


subtest 'font loading from content stream', {
    if (try require PDF::Font::Loader) === Nil {
        skip 'PDF::Font::Loader is needed for this test';
    }
    else {
        sub prefix:</>($s) { PDF::COS::Name.COERCE($s) };
        my $page = $pdf.add-page;
        my %Resources =
            :Procset[ /'PDF', /'Text'],
            :Font{
            :F1{
                :Type(/'Font'),
                :Subtype(/'Type1'),
                :BaseFont(/'Helvetica'),
                :Encoding(/'MacRomanEncoding'),
            },
        };
        $page.Resources = %Resources;
        lives-ok: {
            $page.graphics: {
                .ops: "BT /F1 24 Tf";
                .text-position = 15, 25;
                .say: "Bye for now";
                .EndText;
            }
        }
    }
}

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

$pdf.save-as: "t/text-box.pdf";
