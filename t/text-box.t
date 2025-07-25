use v6;
use Test;
plan 21;
use lib 't';
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Text::Box;
use PDF::Content::Text::Line;
use PDF::Content::Font::CoreFont;
use PDF::Content::Color :color, :ColorName;
use PDFTiny;

my \nbsp = "\c[NO-BREAK SPACE]";
my @chunks =  PDF::Content::Text::Box.comb: "z80 a-b. -3   {nbsp}A{nbsp}bc{nbsp} 42";
is-deeply @chunks, ["z80", " ", "a-", "b.", " ", "-", "3", "   ", "{nbsp}A{nbsp}bc{nbsp}", " ", "42"], 'text-box comb';

my PDF::Content::Text::Box $text-box;
my $text = "Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my $font-size = 16;
my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my $height = 20;
my PDFTiny $pdf .= new;

subtest 'text box basic', {
    $text-box .= new( :$text, :$font, :$font-size, :$height, );
    is $text-box.text, $text;
    is $text-box.font-size, 16;
    is $text-box.height, 20;
    is $text-box.align, 'left', 'default align';
    is $text-box.valign, 'top', 'default valign';
    is $text-box.baseline, 'alphabetic';
    is $text-box.baseline-shift, 0;
    is-approx $text-box.space-width, 4.448, 'space-width';
    is-approx $text-box.content-width, 369.776, '$.content-width';
    is-approx $text-box.content-height, 17.6, '$.content-height';
}

subtest 'text box line', {
    is +$text-box.lines, 1;
    my PDF::Content::Text::Line:D $line = $text-box.lines.head;
    is-approx $line.word-gap, 4.448;
    is-approx $text-box.content-width, 369.776;
    lives-ok { $line.word-gap = 10.0 }
    is-approx $line.word-gap, 10.0;
    is-approx $text-box.content-width, 408.64;
}

subtest 'baseline adjustments',  {
    temp $text-box .= clone( :baseline<hanging> );
    is $text-box.baseline, 'hanging';
    is-approx $text-box.baseline-shift, -11.488;
    $text-box .= clone( :baseline<bottom> );
    is $text-box.baseline, 'bottom';
    is-approx $text-box.baseline-shift, 3.312;
    
}
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
my @rects;
subtest 'text box rendering', {
    $gfx.Save;
    $gfx.BeginText;
    $gfx.text-position = [100, 350];
    $gfx.FillColor = color Blue;
    is-deeply $gfx.text-position, (100.0, 350.0), 'text position';
    @rects.push: $gfx.say( $text-box );
    is-deeply $gfx.text-position, (100.0, 350 - 17.6), 'text position';
    $text-box .= new( :$text, :$font, :$font-size, :squish );
    is-approx $text-box.content-width, 365.328, '$.content-width (squished)';
    is-approx $text-box.content-height, 17.6, '$.content-height (squished)';
    $text-box.TextRise = $text-box.baseline-shift('bottom');
    @rects.push: $gfx.print( $text-box, :!preserve );
    $gfx.EndText;
    $gfx.Restore;
}

$text-box .= clone: :width(250);
is +$text-box.width, 250, '$.clone with width constraint';
given $text-box.content-width {
    ok $_ <= 250, '$.clone content-width'
        or diag "content-width: $_ !<= 250"
}
is-approx $text-box.height, 35.2, 'text-box height';
is +$text-box.lines, 2, '$.clone with width constraint';
given $text-box.lines[1] -> $line {
    is-approx $line.height, 16, 'first line height';
    is-approx $text-box.height, 35.2, 'text-box height';
    $line.height -= 2;
    is-approx $text-box.height, 33, 'text-box height - adjusted';
}

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
        :Tf[ :name<F1>, (16)],
        :Tj[ :literal("Hello.  Ting, ting-ting. Attention! \x[85] ATTENTION! ")],
        :TL[ 17.6 ],
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
        .text-position = 100, 650;
        @rects.push: .say: $text-box;
        is $text-box.lines[0].text, 'Lorem ipsum dolor sit';
        is $text-box.lines[1].text, 'amet, consectetur';
        is-deeply  $text-box.Str.lines, ('Lorem ipsum dolor sit', 'amet, consectetur');
        is $text-box.overflow.join, "adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
        $text = '...' ~ $text-box.overflow.join;
        $text-box .= clone: :$text;
        @rects.push: .say: $text-box;
        is $text-box.overflow.join, 'incididunt ut labore et dolore magna aliqua.';
        @rects.push: .say: '...' ~ $text-box.overflow.join;
    }
}

subtest 'zero width spaces', {
    $gfx.text: {
        $text = q:to<END>.chomp;
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        END
        $text ~~ s:g/' '/\c[ZERO WIDTH SPACE]/;
        my $width = 200;
        $height = 50;
        $text-box .= new( :$text, :$font, :$font-size, :$width, :$height );
        .text-position = 100, 500;
        @rects.push: .say: $text-box;
        is $text-box.lines[0].text, 'Loremipsumdolorsitamet,';
        is $text-box.lines[1].text, 'consecteturadipiscingelit,';
        is-deeply  $text-box.Str.lines, ('Loremipsumdolorsitamet,', 'consecteturadipiscingelit,');
        is-deeply $text-box.overflow.join.subst("\c[ZERO WIDTH SPACE]", '|', :g), 'sed|do|eiusmod|tempor|incididunt|ut|labore|et|dolore|magna|aliqua.';
        $text = '...' ~ $text-box.overflow.join;
        $text-box .= clone: :$text;
        @rects.push: .say: $text-box;
        is $text-box.overflow.join, "dolore\c[ZERO WIDTH SPACE]magna\c[ZERO WIDTH SPACE]aliqua.";
        @rects.push: .say: '...' ~ $text-box.overflow.join;
    }
}

subtest 'variable spaces', {
    $gfx.text: {
        $text = "Spaces:en-space\c[EN SPACE]space tab\tem-space\c[EM SPACE]em-quad\c[EM QUAD]three\c[THREE-PER-EM SPACE]four\c[FOUR-PER-EM SPACE]six\c[SIX-PER-EM SPACE]thin\c[THIN SPACE]hair\c[HAIR SPACE]zero\c[ZERO WIDTH SPACE]. " x 2;
        my $width = 400;
        $height = 100;
        $text-box .= new( :$text, :$font, :$font-size, :$width, :$height );
        .text-position = 100, 300;
        @rects.push: .say: $text-box;
    }
}

subtest 'empty text box', {
    $gfx.text: {
        .text-position = 100, 150;
        @rects.push: $gfx.print: "empty text follows..";
        @rects.push: $gfx.say: "";
        my ($r1, $r2) = @rects.tail(2);
        is-deeply $r2, ($r1[2], $r1[1], $r1[2], $r1[3]);
        @rects.push: $gfx.say: "next line";
    }
}

subtest 'text box margins', {
    $text-box .= new( :$text, :$font, :$font-size, :width(250), :$height, :margin-bottom(2) );
    is $text-box.text, $text;
    is $text-box.font-size, 16;
    is $text-box.height, $height;
    is-deeply $text-box.margin-left, 0;
    is-deeply $text-box.margin-bottom, 2;
    is-deeply $text-box.bbox, (0, -2, 250, $height);
    is-deeply $text-box.bbox(1,2), (1, 0, 251, $height+2);
    $text-box.offset = [-2, 3];
    is-deeply $text-box.bbox, (-2, 1, 248, $height+3);
}

$gfx.graphics: {
    sub draw-rect(@rect, :@color = (.5, .01, .01)) {
        $gfx.tag: 'Artifact', {
            my @r = .[0], .[1], .[2] - .[0], .[3] - .[1]
                given @rect;
            $gfx.StrokeAlpha = .5;
            $gfx.StrokeColor = color @color;
            $gfx.paint: :stroke, { .Rectangle(|@r); }
        }
    }

    draw-rect($_) for @rects;
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
        # ensure consistant document ID generation
        $pdf.id = $*PROGRAM.basename.fmt('%-16.16s');

        $pdf.save-as: "t/text-box.pdf";
    }
}

