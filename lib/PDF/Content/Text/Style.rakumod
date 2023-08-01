class PDF::Content::Text::Style is rw {

    use PDF::Content::Color :&color;

    has $.font is required;
    has Numeric $.font-size = 16;
    has Numeric $.leading = 1.1;
    has Bool    $.kern;
    has Numeric $!space-width = 300;

    # directly mapped to graphics state
    has Numeric $.WordSpacing  is built;
    has Numeric $.CharSpacing  is built;
    has Numeric $.HorizScaling is built;
    has UInt    $.TextRender   is built;
    has Numeric $.TextRise     is built;

    my subset Baseline of Str is export(:BaseLine) where 'alphabetic'|'top'|'bottom'|'middle'|'ideographic'|'hanging'|Any:U;

    method !build(
        :$!CharSpacing = 0,
	:$!WordSpacing = 0,
	:$!HorizScaling = 100,
        :$!TextRender = 0,
	:$!TextRise = 0,
    ) {
        with $!font {
            if .stringwidth(' ') -> $sw {
                $!space-width = $sw;
            }
        }
    }
    submethod TWEAK(*%o) {
        %o<TextRise> //= self.baseline-shift($_)
            with %o<baseline>;
        with %o<gfx> {
            %o<CharSpacing>  //= .CharSpacing;
            %o<WordSpacing>  //= .WordSpacing;
            %o<HorizScaling> //= .HorizScaling;
            %o<TextRender>   //= .TextRender;
            %o<TextRise>     //= .TextRise;
        }
        self!build(|%o);
    }

    method baseline-shift(Baseline $_) {
        my \h = $!font.height($!font-size, :hanging, :from-baseline);
	when 'alphabetic'  { 0 }
	when 'top'         { - h }
	when 'bottom'      {   $.font-height(:hanging)   - h }
	when 'middle'      {   $.font-height(:hanging)/2 - h }
	when 'ideographic' {   $!font-size - h }
	when 'hanging'     { - h }
	default            { 0 }
    }

    method space-width {
        $!space-width * $!font-size / 1000;
    }

    method underline-position {
        ($!font.underline-position // -100) * $!font-size / 1000;
    }

    method underline-thickness {
        ($!font.underline-thickness // 50) * $!font-size / 1000;
    }

    method font-height(|c) {
        $!font.height: $!font-size, |c;
    }
}
