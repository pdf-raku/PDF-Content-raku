use v6;
use Test;
plan 9;

use PDF::Content;
use PDF::Grammar::Test :is-json-equiv;
use lib '.';
use t::GfxParent;

my $parent = { :Font{ :F1{} }, } does t::GfxParent;

my PDF::Content $g .= new: :$parent;
$g.graphics: { .BeginText; .ShowText("Hi"); .EndText;};
is-json-equiv [$g.ops], [:q[], :BT[], :Tj[:literal("Hi")], "ET" => [], :Q[]];

$g .= new: :$parent;
$g.text: { .ShowText("Hi"); };
is-json-equiv [$g.ops], [:BT[], :Tj[:literal("Hi")], "ET" => [], ];

$g .= new: :$parent;
$g.marked-content: 'Foo', {
    .BeginText;
    .ShowText("Hi");
    .EndText };
is-json-equiv [$g.ops], [:BMC[:name("Foo")], :BT[], :Tj[:literal("Hi")], "ET" => [], :EMC[]];

$g .= new: :$parent;
$g.marked-content: 'Foo', :props{ :Bar{ :Baz(42) } }, {
   .BeginText;
   .ShowText("Hi");
   .EndText;
};
is-json-equiv [$g.ops], [:BDC[:name("Foo"), :dict{:Bar(:dict{:Baz(:int(42))})}], "BT" => [], :Tj[:literal("Hi")], "ET" => [], :EMC[]];

my $props = { :MCID(42) };

$g .= new: :$parent;
$g.marked-content: 'Foo', :$props, {
   .marked-content: 'Nested',  sub ($) { };
};
$g.marked-content: 'Bar', sub ($) { };

my Array $tags = $g.tags;
is +$tags, 2, 'top level tags';
is $tags[0].gist, '<Foo><Nested/></Foo>';
is $tags[1].gist, '<Bar/>';

is $tags[0].mcid, 42, 'marked content id';
$tags[1].mcid = 99;
is $tags[1].mcid, 99, 'marked content id';

done-testing;
