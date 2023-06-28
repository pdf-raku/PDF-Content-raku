use v6;
use Test;
plan 126;

use lib 't';
use PDF;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content;
use PDF::Content::Canvas;
use PDF::Content::Ops :OpCode;
use PDF::Content::Matrix :scale;
use PDFTiny;

my PDFTiny $pdf .= new;
my PDF::Content $g = $pdf.add-page.gfx;
$g.use-font: $pdf.core-font( :family<Helvetica> ); # define resource /F1

$g.op(Save);

is-json-equiv $g.CTM, [1, 0, 0, 1, 0, 0], '$g.CTM - initial';
$g.ConcatMatrix( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.CTM, [10, 1, 15, 2, 3, 4], '$g.GraphicMatrix - updated';
$g.ConcatMatrix( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.CTM, [115, 12, 180, 19, 93, 15], '$g.GraphicMatrix - updated again';

is-json-equiv $g.BeginText, (:BT[]), 'BeginText';

is-json-equiv $g.op('Tf', 'F1', 16), (:Tf[ :name<F1>, 16 ]), 'Tf';
is $g.font-size, 16, '$g.font-size';

is $g.StrokeColorSpace, 'DeviceGray', '$g.StrokeColorSpace - initial';
dies-ok { $g.op('SCN', .2, .3, .4) }, 'SCN (/DeviceGray)';

is-json-equiv $g.op('RG', .1, .2, .3), (:RG[ .1, .2, .3 ] ), 'CS';
is-deeply $g.StrokeColor, (:DeviceRGB[.1, .2, .3]), '$g.StrokeColor - updated';
is $g.StrokeColorSpace, 'DeviceRGB', '$g.StrokeColorSpace - updated';
my $ops1 = +$g.ops;
$g.StrokeColor = :DeviceRGB[.4, .5, .6];
my $ops2 = +$g.ops;
ok $ops2 > $ops1, 'StrokColor Op added';
$g.StrokeColor = :DeviceRGB[.4, .5, .6];
is $ops2, +$g.ops, 'StrokeColor Op optimised';

is $g.StrokeColorSpace, 'DeviceRGB', '$g.StrokeColorSpace - initial';

dies-ok { $g.StrokeColor = :DeviceRGB[.3, .5, .7, .9] }, 'wrong number of colors - dies';

is-deeply $g.StrokeColor, (:DeviceRGB[.4, .5, .6]), '$g.StrokeColor - updated again';

lives-ok { $g.op('SCN', .2, .3, .4) }, 'SCN (/DeviceRGB)';

lives-ok { $g.BeginMarkedContentDict('P', ${ :MCID(42) }) }, '$g.BeginMarkedContent';
is-deeply $g.MoveShowText("move-show-text"), ("'" => [ :literal<move-show-text> ] ), 'MoveShowText';
lives-ok { $g.EndMarkedContent }, '$g.EndMarkedContent';

is $g.tags[0].gist, '<P MCID="42"/>', 'tags';

$g.StrokeColor = :DeviceN[.7, .8];
is-json-equiv $g.StrokeColor, (:DeviceN[.7, .8]), '$g.StrokeColor - deviceN';

is $g.FillColorSpace, 'DeviceGray', '$g.FillColorSpace - initial';
is-json-equiv $g.op('cs', 'DeviceRGB'), (:cs[ :name<DeviceRGB> ] ), 'CS';
is $g.FillColorSpace, 'DeviceRGB', '$g.FillColorSpace - updated';

$ops1 = +$g.ops;
is $g.TextLeading, 0, '$g.TextLeading - initial';
$g.TextLeading = 22;
$ops2 = +$g.ops;
ok $ops2 > $ops1, 'TextLeading Op added';
dies-ok { $g.TextLeading = 'nah' }, 'assigment type-checking';
is $ops2, +$g.ops, 'Op ignored';
$g.TextLeading = 22;
is $ops2, +$g.ops, 'TextLeading Op optimised';
is $g.TextLeading, 22, '$g.TextLeading - updated';

is $g.WordSpacing, 0, '$g.WordSpacing - initial';
$g.WordSpacing = 7.5;
is $g.WordSpacing, 7.5, '$g.WordSpacing - updated';

is $g.HorizScaling, 100, '$g.HorizScaling - initial';
$g.HorizScaling = 150;
is $g.HorizScaling, 150, '$g.HorizScaling - updated';

is $g.TextRise, 0, '$g.TextRise - initial';
$g.TextRise = 1.5;
is $g.TextRise, 1.5, '$g.TextRise - updated';

is $g.CharSpacing, 0, '$g.CharSpacing - initial';
$g.CharSpacing = -.5;
is $g.CharSpacing, -.5, '$g.CharSpacing - updated';

is $g.DashPattern, [[], 0], 'DashPattern - initial';
$g.SetDashPattern([2, 3,], 4);
is $g.DashPattern, [[2, 3], 4], 'DashPattern - updated';
$g.DashPattern = [[3, 5], 6];
is $g.DashPattern, [[3, 5], 6], 'DashPattern - updated';

is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 0, 0], '$g.TextMatrix - initial';

$g.TextMove(10,20);
is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 10, 20], '$g.TextMatrix - moved';
$g.TextMatrix = scale(2,3);
$g.TextMove(15,25);
is-json-equiv $g.TextMatrix, [2, 0, 0, 3, 30, 75], '$g.TextMatrix - moved';
is-deeply $g.text-position, $(15.0, 25.0), 'text-position';
$g.TextMove(5,10);
is-deeply $g.text-position, $(20.0, 35.0), 'text-position';

$g.text-position = (5,10);
is-deeply $g.text-position, $(5.0, 10.0), '$g.text-position - rw accessors';

$g.text-position = (15,20);
is-deeply $g.text-position, $(15.0, 20.0), '$g.text-position - rw accessors';

$g.TextMatrix = [ 10, 1, 15, 2, 3, 4];
is-json-equiv $g.TextMatrix, [10, 1, 15, 2, 3, 4], '$g.TextMatrix - updated';
$g.TextMatrix = ( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.TextMatrix, [10, 1, 15, 2, 3, 4], '$g.TextMatrix - updated again';

is-deeply $g.MoveSetShowText(10.0, 20.0, "move-show-text"), ('"' => [ 10.0, 20.0, :literal<move-show-text> ] ), 'MoveSetShowText';

is $g.WordSpacing, 10.0, '$g.WordSpacing - MoveSetShow';
is $g.CharSpacing, 20.0, '$g.CharSpacing - MoveSetShow';

$g.FillAlpha = 1.0;
my $canvas = $g.canvas;
does-ok $canvas, PDF::Content::Canvas;
nok $canvas<ExtGState>, 'FillAlpha Optimized';
$g.FillAlpha = 0.4;
is $g.ops[*-1], (:gs[:name<GS1>]), 'FillAlpha op';
is-json-equiv $canvas<Resources><ExtGState><GS1>, { :Type<ExtGState>, :ca(0.4)}, 'FillAlpha graphics resource';
$g.FillAlpha = 1.0;
is-json-equiv $canvas<Resources><ExtGState><GS2>, { :Type<ExtGState>, :ca(1.0)}, 'FillAlpha graphics resource';

is-json-equiv $g.op('scn', 0.30, 1, 0.21, 'P2'), (:scn[ .30, 1, .21, :name<P2> ]), 'scn';
is-json-equiv $g.op('TJ', $[ 'hello', 42, 'world']), (:TJ[ :array[ :literal<hello>, 42, :literal<world> ] ]), 'TJ';
is-json-equiv $g.SetStrokeColorSpace('DeviceGray'), (:CS[ :name<DeviceGray> ]), 'Named operator';
dies-ok {$g.op('Tf', 42, 125)}, 'invalid argument dies';
dies-ok {$g.op('Junk', 42)}, 'invalid operator dies';
dies-ok {$g.Str}, 'content with unclosed "BT" - dies';

is-json-equiv $g.op(EndText), (:ET[]), 'EndText';

is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 0, 0, ], '$g.TextMatrix - outside of text block';
is-json-equiv $g.CTM, [115, 12, 180, 19, 93, 15], '$g.GraphicMatrix - outside of text block';

dies-ok {$g.Str}, 'content with unclosed "q" (gsave) - dies';
$g.Restore;

is-json-equiv $g.CTM, [1, 0, 0, 1, 0, 0, ], '$g.GraphicMatrix - restored';
is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 0, 0], '$g.TextMatrix - restored';
is $g.TextLeading, 0, '$g.TextLeading - restored';
is $g.StrokeColorSpace, 'DeviceGray', '$g.StrokeColorSpace - restored';

lives-ok {$g.Str}, 'content with matching BT ... ET  q ... Q - lives';

$g.Save;
is $g.RenderingIntent, 'RelativeColorimetric', 'RenderingIntent, initial';
lives-ok  { $g.RenderingIntent = 'Perceptual' };
is $g.ops.tail, 'ri' => :name<Perceptual>, 'rendering intent - updated';
is $g.Flatness, 0, 'Flatness, initial';
lives-ok  { $g.Flatness = 50 };
is-deeply $g.ops.tail, 'i' => [50], 'rendering intent - updated';
is $g.Flatness, 50, 'Flatness, updated';
$g.Restore;

is $g.RenderingIntent, 'RelativeColorimetric', 'RenderingIntent, restored';
is $g.Flatness, 0, 'Flatness, restored';



$g.Save;
is $g.BlendMode, 'Normal', 'initial BlendMode';
lives-ok {$g.BlendMode = 'Multiply'}, 'BlendMode proxy';
is $g.BlendMode,'Multiply', 'get BlendMode';
$g.Restore;
is $g.BlendMode, 'Normal', 'restored BlendMode';

$g.Save;
is $g.MiterLimit, 10.0, 'default MiterLimit';
lives-ok {$g.MiterLimit = 7.5}, 'MiterLimit proxy';
is $g.MiterLimit, 7.5, 'get MiterLimit';
lives-ok {$g.SetMiterLimit(5.0)}, 'SetMiterLimit';
is $g.MiterLimit, 5.0, 'get MiterLimit';
$g.Restore;
is $g.MiterLimit, 10.0, 'restored BlendMode';

$g .= new: :$canvas;

$g.ops("175 720 m 175 700 l 300 800 400 720 v h S");
is-json-equiv $g.ops, [
    :m[175, 720],
    :l[175, 700],
    :v[300, 800, 400, 720],
    :h[],
    :S[],
], 'basic parse';

my $image-block = 'BI                  % Begin inline image object
    /W 17           % Width in samples
    /H 17           % Height in samples
    /CS /RGB        % Colour space
    /BPC 8          % Bits per component
    /F [/A85 /LZW]  % Filters
ID                  % Begin image data
J1/gKA>.]AN&J?]-<HW]aRVcg*bb.\eKAdVV%/PcZ
%…Omitted data…
%R.s(4KE3&d&7hb*7[%Ct2HCqC~>
EI';

my @image-lines = q:to"EI".lines;;
J1/gKA>.]AN&J?]-<HW]aRVcg*bb.\eKAdVV%/PcZ
%…Omitted data…
%R.s(4KE3&d&7hb*7[%Ct2HCqC~>
EI

$g.ops($image-block);
is-json-equiv $g.ops[*-3], {:BI[:dict{
                                    :W(17),
                                    :H(17),
                                    :CS(:name<RGB>),
                                    :BPC(8),
                                    :F(:array[:name<A85>, :name<LZW>]),
                                     }]}, 'Image BI';

is-json-equiv [$g.ops[*-2]<ID>[0]<encoded>.lines], @image-lines, 'Image ID';
is-json-equiv $g.ops[*-1], (:EI[]), 'Image EI';

lives-ok {$g.content-dump}, 'can write image data';
my @inline-images = $g.inline-images;

is-json-equiv @inline-images, [
    { :Subtype<Image>, :Type<XObject>,
      :BitsPerComponent(8), :ColorSpace<RGB>, :Filter<A85 LZW>,
      :Height(17), :Width(17),  :Length(86), },
], 'inline-images';

is-deeply [@inline-images[0].encoded.lines], @image-lines, 'image lines';

BEGIN our $compile-time = PDF::Content::Ops.parse("BT/F1 16 Tf\n(Hi)Tj ET");
is-json-equiv $compile-time[*-1], (:ET[]), 'compile time ops parse';
$g.ops( $compile-time);
is-json-equiv [ $g.ops[*-4..*] ], [
    :BT[],
    :Tf[:name<F1>, 16],
    :Tj[:literal<Hi>],
    :ET[],
], 'Text block parse';

$g .= new( :comment, :$canvas);

$g.ops("175 720 m 175 700 l 300 800 400 720 v h S");
$g.add-comment("That's all♥!");
is-json-equiv $g.ops, [
    :m[175, 720, :comment<MoveTo>, ],
    :l[175, 700, :comment<LineTo>, ],
    :v[300, 800, 400, 720, :comment<CurveToInitial>, ],
    :h[ :comment<ClosePath>, ],
    :S[ :comment<Stroke>, ],
    :comment["That's all♥!"],
], 'parse and comment';

is-deeply $g.content-dump, $(
    '175 720 m % MoveTo',
    '175 700 l % LineTo',
    '300 800 400 720 v % CurveToInitial',
    'h % ClosePath',
    'S % Stroke',
    "% That's all#2665!",
), 'content with comments';

my PDF::Content $g1 .= new: :$canvas;
lives-ok {$g1.ops: $g.ops;}, "comments import - lives";
is-json-equiv $g1.ops.head, (:m[ 175, 720, ]), 'comments import - head';
is-json-equiv $g1.ops.tail(2).List, (:S[ ], :comment["That's all♥!"]), 'comments import - tail';

$g.Save;
$g.CTM = [0, -2, 2, 0, 40, -20];
is-deeply [ $g.CTM.list ], [0.0, -2.0, 2.0, 0.0, 40.0, -20.0], 'graphics matrix assignment';
$g.Restore;

my ($x, $y) = $g.base-coords(80, 100);
is-deeply ($x, $y), (80, 100), 'base coordinates';

$g.Save;
$g.ConcatMatrix(1,0,0,1,0,792);
$g.ConcatMatrix(2,0,0,2,0,0);
$g.ConcatMatrix(1,0,0,1,75,-25,);
is-deeply [ $g.CTM.list ], [2, 0, 0, 2, 150, 742], "chained matrix transforms";
$g.text: {
    .text-position = 5, 10;

    ($x, $y) = $g.base-coords(80, -100);
    is-deeply ($x, $y), (310, 542), 'graphics to base user coordinates';
    is-deeply $g.user-coords($x, $y).List, (80.0, -100.0);

    ($x, $y) = $g.base-coords(80, -100, :text);
    is-deeply ($x, $y), (320, 562), 'graphics+text to base user coordinates, :text';
    is-deeply $g.user-coords($x, $y, :text).List, (80.0, -100.0);

    ($x, $y) = $g.base-coords(80, -100, :!user);
    is-deeply ($x, $y), (85, -90), 'text to graphics coordinates';
    is-deeply $g.user-coords($x, $y, :!user).List, (80.0, -100.0);
}
$g.Restore;

$g.Save;
$g.ConcatMatrix(1,0,0,1,0,792);
$g.ConcatMatrix(1,0,0,1,150,-50);
$g.ConcatMatrix(2,0,0,2,0,0);
is-deeply [ $g.CTM.list ], [2, 0, 0, 2, 150, 742], "chained matrix transforms";
$g.Restore;

$g.SetCharWidth(12,15);
is $g.char-width, 12, "SetCharWidth";
is $g.char-height, 15, "SetCharWidth";

$g.SetCharWidthBBox(20,25, 1, 2, 25, 30);
is $g.char-width, 20, "SetCharWidthBBox";
is $g.char-height, 25, "SetCharWidthBBox";
is-deeply $g.char-bbox.List, (1, 2, 25, 30), "SetCharWidthBBox";

$g .= new( :$canvas);
$g.Save;
$g.Rectangle(10,10, 150, 100);
$g.paint: :close, :fill;
$g.Restore;

my @painted = [
    :q[],
        :re[10, 10, 150, 100],
        :h[],
        :f[],
    :Q[]
];

is-json-equiv $g.ops, @painted, 'drawing and painting';

$g .= new( :$canvas);
$g.paint: :close, :fill, {
    .Rectangle(10,10, 150, 100);
}

is-json-equiv $g.ops, @painted, 'drawing/painting, block form';

todo "failing on rakudo blead";
lives-ok { $g.?Junk }, 'unknown method/operator: .? invocation';
dies-ok { $g.Junk }, 'unknown method/operator: . invocation';

done-testing;
