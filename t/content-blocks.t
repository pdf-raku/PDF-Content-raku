use v6;
use lib 't';
use Test;
plan 12;
use PDF;
use PDF::Content;
use PDF::Grammar::Test :is-json-equiv;
use PDFTiny;

my PDFTiny $pdf .= new;
my PDF::Content $g = $pdf.add-page.gfx: :!strict;
$g.graphics: { .BeginText; .ShowText("Hi"); .EndText;};
is-json-equiv [$g.ops], [
    :q[],
    :BT[],
    :Tj[:literal("Hi")],
    "ET" => [],
    :Q[]], '.graphics block';

$g = $pdf.add-page.gfx: :!strict;
$g.text: { .ShowText("Hi"); };
is-json-equiv [$g.ops], [
    :BT[],
    :Tj[:literal<Hi>],
    "ET" => [], ], '.text block';

$g = $pdf.add-page.gfx: :!strict;
given $g {
    .BeginMarkedContent('Foo');
    .BeginText;
    .ShowText("Hi");
    .EndText;
    .EndMarkedContent;
};
is-json-equiv [$g.ops], [
    :BMC[:name<Foo>,],
    :BT[],
    :Tj[:literal<Hi>],
    "ET" => [],
    :EMC[],
], '.tag content block';

$g = $pdf.add-page.gfx: :!strict;
$g.tag: 'Foo', :Bar{ :Baz }, {
   .BeginText;
   .ShowText("Hi");
   .EndText;
};
is-json-equiv [$g.ops], [
    :BDC[:name<Foo>, :dict{:Bar(:dict{:Baz(True)}),}],
    "BT" => [],
    :Tj[:literal<Hi>],
    "ET" => [],
    :EMC[], ], '.tag content block with dict';

my $props = { :MCID(42) };

$g = $pdf.add-page.gfx: :!strict;
$g.tag: 'Foo', |$props, {
   .tag: 'Nested',  sub ($) { };
   $g.MarkPoint('A');
   $g.XObject('Img1');
};
$g.tag: 'Bar', sub ($) { };
$g.tag('B', :MCID(99));

my PDF::Content::Tag @tags = $g.tags.children;
is +@tags, 3, 'top level tags';

is @tags[0].gist, '<Foo MCID="42"><Nested/><A/></Foo>', '@tags[0]';
is @tags[1].gist, '<Bar/>', '@tags[1]';
is @tags[2].gist, '<B MCID="99"/>', '@tags[2]';

is @tags[0].mcid, 42, 'marked content id';
is @tags[0].name, 'Foo', 'marked content name';
is @tags[0].op, 'BDC', 'marked content op';

@tags[1].mcid = 99;
is @tags[1].mcid, 99, 'marked content id[1]';

done-testing;
