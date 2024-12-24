#| style setting for a text box
unit class PDF::Content::Text::Style is rw;

use PDF::Content::Color :&color;
my subset TextDirection of Str:D where 'ltr'|'rtl';

has $.font is required;
has Numeric $.font-size = 16;
has Numeric $.leading = 1.1;
has Bool    $.kern;
has Bool    $.shape;
has Str     $.script;
has Str     $.lang;
has Numeric $!space-width = 300;
has $!units-per-EM = 1000;
has TextDirection $.direction = 'ltr';
has Str $!hypen;
has List $!hypen-encode;

# directly mapped to graphics state
has Numeric $.WordSpacing  is built;
has Numeric $.CharSpacing  is built;
has Numeric $.HorizScaling is built;
has UInt    $.TextRender   is built;
has Numeric $.TextRise     is built;

my subset Baseline of Str is export(:BaseLine) where 'alphabetic'|'top'|'bottom'|'middle'|'center'|'ideographic'|'hanging'|Any:U;

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
multi method baseline-shift('alphabetic' --> Numeric) { 0 }
multi method baseline-shift(Baseline $_ --> Numeric) {
    my \h = $!font.height($!font-size, :hanging, :from-baseline);
    when 'top'             { - h }
    when 'bottom'          {   $.font-height(:hanging)   - h }
    when 'middle'|'center' {   $.font-height(:hanging)/2 - h }
    when 'ideographic'     {   $!font-size - h }
    when 'hanging'         { - h }
    default                { 0 }
}
=para This returns a positive or negative y-offset in units of points.  The default is C<alphabetic>, which is a zero offset.


#| get/set a numeric font vertical alignment offset
multi method baseline-shift is rw { $!TextRise }

method scale($v) { $v * $!font-size / $!units-per-EM; }

#| return the scaled width of spaces
method space-width { self.scale: $!space-width; }

#| return the scaled underline position
method underline-position {
    self.scale: ($!font.underline-position // -100)
}

#| return the scaled underline thickness
method underline-thickness {
    self.scale: ($!font.underline-thickness // 50)
}

#| return the scaled font height
method font-height(|c) {
    $!font.height: $!font-size, |c;
}

method encode(Str:D $atom) {
    my List $encoded;
    my Numeric $width;
    if $!shape || $!script || $!lang {
        my Bool $kern = $!kern || $!shape;
        given $!font.shape($atom, :$kern, :$!script, :$!lang) {
            $encoded := .[0];
            $width = .[1];
        }
    }
    elsif $!kern {
        given $!font.kern($atom) {
            $encoded := .List given .[0].list.map: {
                .does(Numeric) ?? -$_ !! $!font.encode($_);
            }
            $width = .[1];
        }
    }
    else {
        $encoded := ( $!font.encode($atom), );
        $width = $!font.stringwidth($atom);
    }
    $width *= $!font-size * $!HorizScaling / 100000;
    $width += ($atom.chars - 1) * $!CharSpacing
        if $.CharSpacing > -$!font-size;
    ($encoded, $width);
}

has Str $!hyphen;
has List $!hyphen-encoding;

method !hyphen-init {
    $!hyphen = "\c[HYPHEN]";
    $!hyphen-encoding = self.encode: $!hyphen;
    unless $!hyphen-encoding[1] {
        $!hyphen = "\c[HYPHEN-MINUS]";
        $!hyphen-encoding = self.encode: $!hyphen;
    }
}

method hyphen {
    self!hyphen-init without $!hyphen;
    $!hypen;
}

method hyphen-encoding {
    self!hyphen-init without $!hyphen;
    $!hyphen-encoding;
}

method hyphen-width { self.hyphen-encoding[1] }
       
