use v6;

class PDF::Content::Text::Line {

    use PDF::Content::Ops :OpCode;

    has List @.words;
    has Numeric $.height is rw is required;
    has Numeric $.word-width is rw = 0; #| sum of word widths
    has Numeric $.word-gap = 0;
    has Numeric $.indent is rw = 0;
    has Numeric $.align is rw = 0;
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

    method content(:$font!, Numeric :$font-size!, Numeric :$x-shift = 0, :$space-pad = 0) {
        my Numeric \scale = -1000 / $font-size;
        my subset Str-or-Pos where Str|Numeric;
        my Str-or-Pos @line;
        constant Space = ' ';

        my Numeric $indent = $!align + $!indent + $x-shift;
        $indent = ($indent * scale).round.Int;
        @line.push: $indent
            if $indent;
        my int $wc = 0;

        # flatten words. insert spaces and space adjustments.
        # Ensure we add spaces - as recommended in [PDF-32000 14.8.2.5 - Identifying Word Breaks]
        for ^+@!words -> $i {
            my $spaces := @!spaces[$i];
            if $spaces {
	        @line.push: Space x $spaces;
                @line.push: $space-pad * $spaces
                    unless $space-pad =~= 0;
            }
            @line.append: @!words[$i].list;
        }

        my @out;
        my $prev := Int;
        for @line {
            my $tk := $_ ~~ Str ?? $font.encode($_) !! $_;
            if $tk ~~ Str && $prev ~~ Str {
                # coalesce adjacent strings
                @out.tail ~= $tk;
            }
            else {
                @out.push: $tk;
            }
            $prev := $tk;
        }

        @out == 1 && @out.head.isa(Str)
            ?? ((OpCode::ShowText) => [@out.head,])
            !! ((OpCode::ShowSpaceText) => [@out,]);

    }

}
