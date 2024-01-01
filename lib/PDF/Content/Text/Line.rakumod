#| A single line of a text box
unit class PDF::Content::Text::Line;

use PDF::Content::Ops :OpCode;
use Method::Also;

has List @.words;
has Numeric $.height is rw is required;
has Numeric $.word-width is rw = 0; #| sum of word widths
has Numeric $.word-gap = 0;
has Numeric $.indent is rw = 0;
has Numeric $.align = 0;
has UInt @.spaces;

method content-width returns Numeric {
    $!indent  +  $!word-width  +  @!spaces.sum * $!word-gap;
}

multi method align('justify', Numeric :$width! ) {
    my Numeric \content-width = $.content-width;
    my Numeric \wb = +@!spaces.sum;
    my Numeric \stretch = $width / content-width;

    if content-width && wb && 1.0 < stretch < 2.0 {
        $!word-gap += ($width - content-width) / wb;
        $!align = 0;
    }
}

multi method align('left') {
    $!align = 0;
}

multi method align('right') {
    $!align = - $.content-width;
}

multi method align('center') {
    $!align = - $.content-width  /  2;
}

multi method align { $!align }

sub coalesce(@line is raw) {
    my @l;
    my $prev;
    for @line {
        if $_ ~~ Str && $prev ~~ Str {
            @l.tail ~= $_;
        }
        else {
            @l.push: $_;
            $prev := $_;
        }
    }
    @l;
}

method content(:$font!, Numeric :$font-size!, :$space-pad = 0) {
    my Numeric \scale = -1000 / $font-size;
    my subset Atom where Str|Numeric;
    my Atom @line;
    constant Space = ' ';
    my int $wc = 0;

    if $!align + $!indent -> $indent {
        @line.push: ($indent * scale).round.Int;
    }

    # flatten words. insert spaces and space adjustments.
    # Ensure we add spaces - as recommended in [PDF-32000 14.8.2.5 - Identifying Word Breaks]
    for ^+@!words -> $i {
        my $spaces := @!spaces[$i];
        if $spaces {
            @line.push: $font.encode(Space x $spaces);
            @line.push: $space-pad * $spaces
                unless $space-pad =~= 0;
        }
        @line.append: @!words[$i].list;
    }
    @line .= &coalesce;

    @line == 1 && @line.head.isa(Str)
        ?? ((OpCode::ShowText) => [@line.head,])
        !! ((OpCode::ShowSpaceText) => [@line,]);

}

method text is also<Str> {
    join '', @!words.kv.map: -> $i, $w {
        ((' ' x @!spaces[$i]).Slip, $w.grep(Str).Slip)
    }
}

