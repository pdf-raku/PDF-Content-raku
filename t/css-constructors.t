use v6;
use PDF::Basic;
use PDF::Basic::CSS;
use PDF::Basic::Units :ALL;
use Test;

my $css;

sub to-hash(PDF::Basic::CSS::Boxed $box) {
    my %h;
    for <top left bottom right> -> $e {
        %h{$e} = $_ with $box."$e"();
    }
    %h;
}

$css = PDF::Basic::CSS.new;
is-deeply to-hash($css.border-width), { :top(0px), :left(0px), :bottom(0px), :right(0px) }, "intial length value";
is-deeply to-hash($css.border-style), { :top<none>, :left<none>, :bottom<none>, :right<none> }, "intial length value";

$css = PDF::Basic::CSS.new( :border-width(2px) );
is-deeply to-hash($css.border-width), { :top(2px), :left(2px), :bottom(2px), :right(2px) }, "Numeric -> Edge coercement";

$css = PDF::Basic::CSS.new( :border-width[2px, 3px] );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Array -> Edge coercement";

$css = PDF::Basic::CSS.new( :border-width{ :top(2px), :right(3px) } );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Hash -> Edge coercement";

my $border-width = $css.border-width;
$css = Nil;

$css = PDF::Basic::CSS.new( :$border-width );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Construction from Edge object";

for [255, 0, 0], "#f00", "#ff0000", "red", "Red", "rgb(255,0,0)", "RGB(100%,0%, 0)"  -> $background-color {
    $css = PDF::Basic::CSS.new( :$background-color );
    is-deeply $css.background-color.Array, [255, 0 , 0], "color: {$background-color.perl}";
}

$css = PDF::Basic::CSS.new( :border-style<dotted dashed> );
is-deeply to-hash($css.border-style), { :top<dotted>, :left<dashed>, :bottom<dotted>, :right<dashed> }, "Construction from Edge object";

$css = PDF::Basic::CSS.new( :border-width-left(5px) );
is-deeply to-hash($css.border-width), { :top(0px), :left(5px), :bottom(0px), :right(0px) }, "single side contruction";
is $css.border-width-left, 5px, 'single side accessor';
is $css.border-width-right, 0px, 'single side accessor';

done-testing;

