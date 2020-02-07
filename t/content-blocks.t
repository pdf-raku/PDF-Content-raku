use v6;
use Test;
plan 12;
use PDF;
use PDF::Content;
use PDF::Grammar::Test :is-json-equiv;
use lib 't/lib';
use FakeGfxParent;

my $parent = { :Type<Page>, :Font{ :F1{} }, } does FakeGfxParent;

my PDF::Content $g .= new: :$parent, :!strict;
$g.graphics: { .BeginText; .ShowText("Hi"); .EndText;};
is-json-equiv [$g.ops], [
    :q[],
    :BT[],
    :Tj[:literal("Hi")],
    "ET" => [],
    :Q[]], '.graphics block';

$g .= new: :$parent, :!strict;
$g.text: { .ShowText("Hi"); };
is-json-equiv [$g.ops], [
    :BT[],
    :Tj[:literal<Hi>],
    "ET" => [], ], '.text block';

$g .= new: :$parent, :!strict;
$g.tag: 'Foo', {
    .BeginText;
    .ShowText("Hi");
    .EndText };
is-json-equiv [$g.ops], [
    :BDC[:name<Foo>, :dict{:MCID(:int(1))}],
    :BT[],
    :Tj[:literal<Hi>],
    "ET" => [],
    :EMC[], ], '.tag content block';

$g .= new: :$parent, :!strict;
$g.tag: 'Foo', :Bar{ :Baz }, {
   .BeginText;
   .ShowText("Hi");
   .EndText;
};
is-json-equiv [$g.ops], [
    :BDC[:name<Foo>, :dict{:Bar(:dict{:Baz(:bool)}),  :MCID(:int(2))}],
    "BT" => [],
    :Tj[:literal<Hi>],
    "ET" => [],
    :EMC[], ], '.tag content block with dict';

my $props = { :MCID(42) };

$g .= new: :$parent, :!strict;
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
is @tags[1].gist, '<Bar MCID="43"/>', '@tags[1]';
is @tags[2].gist, '<B MCID="99"/>', '@tags[2]';

is @tags[0].mcid, 42, 'marked content id';
is @tags[0].name, 'Foo', 'marked content name';
is @tags[0].op, 'BDC', 'marked content op';

@tags[1].mcid = 99;
is @tags[1].mcid, 99, 'marked content id[1]';

done-testing;
