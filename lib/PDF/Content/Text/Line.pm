use v6;

class PDF::Content::Text::Line {

    use PDF::Content::Ops :OpNames;

    has @.atoms;
    has Numeric $.indent is rw = 0;

    method actual-width returns Numeric { [+] @!atoms.map({ .width + .space }) };

    multi method align('justify', Numeric :$width! ) {
        my Numeric $actual-width = $.actual-width;

        if $width > $actual-width && $width / $actual-width < 2.0 {
            # stretch both word boundaries and non-breaking spaces
            my @elastics = @!atoms.grep: *.elastic;

            if +@elastics {
                my Numeric $stretch = ($width - $actual-width) / +@elastics;
                .space += $stretch
                    for @elastics;
            }

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

    method content(Numeric :$font-size!, Numeric :$space-size!, Numeric :$word-spacing = 0, Numeric :$x-shift = 0) {

        my Numeric $scale = -1000 / $font-size;
        my subset Str-or-Pos of Any where Str|Numeric;
        my Str-or-Pos @line;

        my Numeric $indent = $!indent + $x-shift;
        $indent =  ($indent * $scale).round.Int;
        @line.push: $indent
            if $indent;
        my Numeric $pos;

        for $.atoms.list {
            @line.push: $pos
                if $pos;

	    $pos = .space;
	    $pos += $word-spacing
		if $pos > 0 && $word-spacing;
	    $pos = ($pos * $scale).round.Int;

            my Str $str = .encoded // .content;

	    if $pos && $space-size && abs($pos - $space-size) <= 1 {
		# optimization: use an actual space, when it fits
		$str ~= ' ';
		$pos = 0;
	    }

	    if $str.chars {
		if @line && @line[*-1] ~~ Str {
		    # on a string segment - concatonate
		    @line[*-1] ~= $str
		}
		else {
		    # start a new string segment
		    @line.push: $str;
		}
	    }

        }

        (OpNames::ShowSpaceText) => [@line,];

    }

}
