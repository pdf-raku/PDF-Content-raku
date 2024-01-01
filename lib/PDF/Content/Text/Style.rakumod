#| style setting for a text box
unit class PDF::Content::Text::Style is rw;

use PDF::Content::Color :&color;

has $.font is required;
has Numeric $.font-size = 16;
has Numeric $.leading = 1.1;
has Bool    $.kern;
has Bool    $.shape;
has Numeric $!space-width = 300;
has $!units-per-EM = 1000;

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
        try { $!units-per-EM = .units-per-EM || 1000 }
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
    self!build: |%o;
}

=head2 Methods

#| compute a vertical offset for a named font alignment mode
multi method baseline-shift(Baseline $_ --> Numeric) {
    my \h = $!font.height($!font-size, :hanging, :from-baseline);
    when 'alphabetic'  { 0 }
    when 'top'         { - h }
    when 'bottom'      {   $.font-height(:hanging)   - h }
    when 'middle'      {   $.font-height(:hanging)/2 - h }
    when 'ideographic' {   $!font-size - h }
    when 'hanging'     { - h }
    default            { 0 }
}
=para This returns a positive or negative y-offset in units of points.  The default is C<alphabetic>, which is a zero offset.


#| get/set a numeric font vertical alignment offset
multi method baseline-shift is rw { $!TextRise }

#| return the scaled width of spaces
method space-width {
    $!space-width * $!font-size / $!units-per-EM;
}

#| return the scaled underline position
method underline-position {
    ($!font.underline-position // -100) * $!font-size / $!units-per-EM;
}

#| return the scaled underline thickness
method underline-thickness {
    ($!font.underline-thickness // 50) * $!font-size / $!units-per-EM;
}

#| return the scaled font height
method font-height(|c) {
    $!font.height: $!font-size, |c;
}

