use v6;

class PDF::Content::Text::Line {

    use PDF::Content::Ops :OpNames;

    has @.words;
    has Numeric $.word-width is rw = 0; #| sum of word widths
    has Numeric $.word-spacing = 0;
    has Numeric $.indent is rw = 0;
    has Bool @.word-boundary;

    method actual-width returns Numeric {
        $!word-width + @!word-boundary.grep(*.so) * $!word-spacing;
    }

    multi method align('justify', Numeric :$width! ) {
        my Numeric \actual-width = $.actual-width;
        my Numeric \wb = +@!word-boundary.grep: *.so;

        if actual-width && wb && 1.0 < $width / actual-width < 2.0 {
            $!word-spacing += ($width - actual-width) / wb;
            $!indent = 0;
        }
    }

    multi method align('left') {
        $!indent = 0;
    }

    multi method align('right') {
        $!indent = - $.actual-width;
    }

    multi method align('center') {
        $!indent = - $.actual-width  /  2;
    }

    method content(Numeric :$font-size!, Numeric :$space-size!, Numeric :$x-shift = 0) {
        my Numeric \scale = -1000 / $font-size;
        my subset Str-or-Pos of Any where Str|Numeric;
        my Str-or-Pos @line;

        my Numeric $indent = $!indent + $x-shift;
        $indent =  ($indent * scale).round.Int;
        @line.push: $indent
            if $indent;
        my Numeric $pos;
        my int $wc = 0;
        #| use a real space, if it fits
        my \space-width = (scale * $!word-spacing).round.Int;
        my \space = abs(space-width - $space-size) <= 1 ?? ' ' !! space-width;

        for @!words -> \w {
	    @line.push(space) if @!word-boundary[$wc++];
            @line.append: w.list;
        }

        #| coalesce adjacent strings
        my @out;
        my $n = 0;
        my $prev = 0;
        for @line {
            if $_ ~~ Str && $prev ~~ Str {
                @out[$n-1] ~= $_
            }
            else {
                @out[$n++] = $_;
            }
            $prev = $_;
        }

        (OpNames::ShowSpaceText) => [@out,];

    }

}
