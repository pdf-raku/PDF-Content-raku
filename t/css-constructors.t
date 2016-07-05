use v6;
use PDF::Content;
use PDF::Content::CSS;
use PDF::Content::Units :ALL;
use Test;

my $css;

sub to-hash(PDF::Content::CSS::Boxed $box) {
    my %h;
    for <top left bottom right> -> $e {
        %h{$e} = $_ with $box."$e"();
    }
    %h;
}

$css = PDF::Content::CSS.new;
is-deeply to-hash($css.border-width), { :top(0px), :left(0px), :bottom(0px), :right(0px) }, "initial length value";
is-deeply to-hash($css.border-style), { :top<none>, :left<none>, :bottom<none>, :right<none> }, "initial length value";

$css = PDF::Content::CSS.new( :border-width(2px) );
is-deeply to-hash($css.border-width), { :top(2px), :left(2px), :bottom(2px), :right(2px) }, "Numeric -> Edge coercement";

$css = PDF::Content::CSS.new( :border-width[2px, 3px] );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Array -> Edge coercement";

$css = PDF::Content::CSS.new( :border-width{ :top(2px), :right(3px) } );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Hash -> Edge coercement";

my $border-width = $css.border-width;
$css = Nil;

$css = PDF::Content::CSS.new( :$border-width );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Construction from Edge object";

for [255, 0, 0], "#f00", "#ff0000", "red", "Red", "rgb(255,0,0)", "RGB(100%,0%, 0)"  -> $background-color {
    $css = PDF::Content::CSS.new( :$background-color );
    is-deeply $css.background-color.Array, [255, 0 , 0], "color: {$background-color.perl}";
}

$css = PDF::Content::CSS.new( :border-style<dotted dashed> );
is-deeply to-hash($css.border-style), { :top<dotted>, :left<dashed>, :bottom<dotted>, :right<dashed> }, "Construction from Edge object";

$css = PDF::Content::CSS.new( :border-width-left(5px) );
is-deeply to-hash($css.border-width), { :top(0px), :left(5px), :bottom(0px), :right(0px) }, "single side contruction";
is $css.border-width-left, 5px, 'single side accessor';
is $css.border-width-right, 0px, 'single side accessor';

# try some coercements from CSS style declarations

for ('color: blue' => {},
     'line-height: 1.1px' => {},
     'border: 2px solid blue' => {:todo("border properties")}) {
    my $style = .key;
    todo $_ with .value<todo>;
    lives-ok { $css = PDF::Content::CSS.new( :$style )}, "css style construction: {.key}";
}

done-testing;

