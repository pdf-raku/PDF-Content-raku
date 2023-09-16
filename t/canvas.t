use v6;
use Test;
plan 4;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Canvas;
use PDF::Content::Ops :OpCode;

class Canvas does PDF::Content::Canvas {
    has Str $.decoded;
    has %.Resources;
};

my Canvas $gfx .= new(:decoded("BT ET .5 0 0 rg"));
is-deeply $gfx.render.Str.lines, ("q", "  BT", "  ET",  "  0.5 0 0 rg", "Q"), "unsafe content has been wrapped";
is-deeply $gfx.has-pre-gfx, False, '.has-pre-gfx()';

$gfx .= new(:decoded("BT ET .5 0 0 rg"));
is-deeply $gfx.render(:!strict, :!tidy).Str.lines, ("BT", "ET", "0.5 0 0 rg"), ":!tidy disables wrapping";

$gfx .= new(:decoded("BT ET q .5 0 0 rg Q"));
is-deeply $gfx.render.Str.lines, ("BT", "ET", "q", "  0.5 0 0 rg", "Q"), "safe content detected";

done-testing;
