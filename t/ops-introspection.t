use v6;
use Test;
plan 18;

use lib 't';
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content;
use PDF::Content::Ops :OpCode, :LineCaps, :LineJoin, :GraphicsContext;
use PDF::Content::Matrix :scale;
use PDF::IO::Writer;
use PDFTiny;

my $dummy-font = %() does role { method cb-finish {} }

my %gs-initial = %(
    :BlendMode<Normal>,
    :CTM[1, 0, 0, 1, 0, 0],
    :CharSpacing(0),
    :DashPattern[[], 0],
    :FillAlpha(1.0),
    :FillColor[0.0],
    :FillColorSpace<DeviceGray>,
    :Flatness(0),
    :Font(Array),
    :HorizScaling(100),
    :LineCap(LineCaps::ButtCaps),
    :LineJoin(LineJoin::MiterJoin),
    :LineWidth(1.0),
    :MiterLimit(10.0),
    :RenderingIntent<RelativeColorimetric>,
    :StrokeAlpha(1.0),
    :StrokeColor[0.0],
    :StrokeColorSpace<DeviceGray>,
    :TextLeading(0),
    :TextMatrix[1, 0, 0, 1, 0, 0],
    :TextRender(0),
    :TextRise(0),
    :WordSpacing(0)
);

my PDFTiny $pdf .= new;
my PDF::Content $g = $pdf.add-page.gfx;

is-json-equiv $g.gsaves, [], 'gsave initial';
is-json-equiv $g.graphics-state, %gs-initial;
is-deeply $g.context, GraphicsContext::Page;

$g.Save;

is-json-equiv $g.gsaves, (%gs-initial,), 'gsave saved';
is-json-equiv $g.gsaves(:delta), (%(), ), 'gsave saved :delta';
is-json-equiv $g.graphics-state(:delta), %(), 'graphics-state :delta';

$g.ConcatMatrix( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.ops, [
    :q[],
    :cm[10, 1, 15, 2, 3, 4],
], '.ops)_';
is PDF::IO::Writer.write-content($g.ops).lines, ('q', '10 1 15 2 3 4 cm'), 'PDF write content';
is-deeply $g.content-dump, ('q', '10 1 15 2 3 4 cm'), 'content-dump';
$g.ConcatMatrix( 10, 1, 15, 2, 3, 4);

$g.BeginText;
my $font = $pdf.core-font( :family<Helvetica> );
$g.use-font($font); # define resource /F1
$g.SetFont('F1', 16);

is-json-equiv $g.gsaves(:delta), [ {:CTM[115, 12, 180, 19, 93, 15], :Font[$font.to-dict, 16]}, ], 'gsave saved :delta';
is-json-equiv $g.graphics-state(:delta), {:CTM[115, 12, 180, 19, 93, 15], :Font[$font.to-dict, 16]}, 'graphics-state :delta';
is-deeply $g.context, GraphicsContext::Text;

$g.tag: 'P', {
    .ShowText("Hi");
};

$g.tag: 'Div', {
    is .tags.map(*.gist).join, '<P/>';
    is .open-tags.map(*.gist).join, '<Div/>';
    .ShowText("There");
};

is $g.tags.map(*.gist).join, '<P/><Div/>';

$g.EndText;
$g.Restore;

is-json-equiv $g.gsaves, [], 'gsave final';
is-json-equiv $g.graphics-state, %gs-initial, 'graphics-state file';
is-deeply $g.context, GraphicsContext::Page, 'context final';

done-testing;
