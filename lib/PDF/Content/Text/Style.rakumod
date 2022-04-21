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

    submethod TWEAK(
        :$gfx,
        Baseline :$baseline,
        :$!CharSpacing  = do with $gfx {.CharSpacing}  else { 0.0 },
	:$!WordSpacing  = do with $gfx {.WordSpacing}  else { 0.0 },
	:$!HorizScaling = do with $gfx {.HorizScaling} else { 100 },
        :$!TextRender   = do with $gfx {.TextRender}   else { 0 },
	:$!TextRise     = do with $baseline {
	    self.baseline-shift($_);
	} else {
	    with $gfx { .TextRise } else { 0.0 };
	}
    ) {
        with $!font {
            if .stringwidth(' ') -> $sw {
                $!space-width = $sw;
            }
        }
    }

    method baseline-shift(Baseline $_) {
        my \h = $!font.height($!font-size, :hanging, :from-baseline);
	when 'alphabetic'  { 0 }
	when 'top'         { - h }
	when 'bottom'      {   $!font.height($!font-size, :hanging)   - h }
	when 'middle'      {   $!font.height($!font-size, :hanging)/2 - h }
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
}
