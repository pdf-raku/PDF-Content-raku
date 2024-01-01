#| Basic PDF core font support
unit class PDF::Content::Font::CoreFont;

=begin pod

=head2 Synopsis

=begin code :lang<raku>
use PDF::Content::Font::CoreFont;
my PDF::Content::Font::CoreFont $font .= load-font( :family<Times-Roman>, :weight<bold> );
say $font.encode("¶Hi");
say $font.stringwidth("RVX"); # 2166
say $font.stringwidth("RVX", :kern); # 2111
=end code

=head2 Methods

=end pod

use PDF::Content::FontObj;
also does PDF::Content::FontObj;

use Font::AFM :UnitsPerEM;
use PDF::Content::Font;
use PDF::Content::Font::Enc::Type1;
use PDF::COS::Dict;
use PDF::COS::Name;

method units-per-EM { UnitsPerEM }

has Font::AFM $.metrics handles <kern>;
has PDF::Content::Font::Enc::Type1 $.encoder handles <encode decode encode-cids enc>;
has PDF::Content::Font $!dict;
class Cache {
    use PDF::Content::Font::Encodings :zapf-glyphs;
    constant %CharSet = %Font::AFM::Glyphs.invert.Hash;

    has Lock $!lock .= new;
    has %!fonts;
    method core-font(Str:D $font-name, PDF::Content::Font::CoreFont $class?, :$enc!, PDF::Content::Font :$dict, |c) {
        $!lock.protect: {
            ($dict.defined ?? $dict.font-obj !! %!fonts{$font-name.lc~'-*-'~$enc}) //= do {
                    my $metrics = Font::AFM.core-font( $font-name );
                    my Str %glyphs = $font-name eq 'zapfdingbats'
                                      ?? %$zapf-glyphs
                                      !! $metrics.Wx.keys.map: {%CharSet{$_} => $_ };
                    my $encoder = PDF::Content::Font::Enc::Type1.new: :$enc, :%glyphs;
                    $class.new( :$encoder, :$metrics, :$dict, |c);
            }
        }
    }
}
my Cache $global-cache .= new;

constant coreFonts = set <
    courier courier-oblique courier-bold courier-boldoblique
    helvetica helvetica-oblique helvetica-bold helvetica-boldoblique
    times-roman times-italic times-bold times-bolditalic
    symbol zapfdingbats
    >;

# font aliases adapted from pdf.js/src/fonts.js
constant stdFontMap = {

    :arialnarrow<helvetica>,
    :arialnarrow-bold<helvetica-bold>,
    :arialnarrow-bolditalic<helvetica-boldoblique>,
    :arialnarrow-italic<helvetica-oblique>,

    :arialblack<helvetica>,
    :arialblack-bold<helvetica-bold>,
    :arialblack-bolditalic<helvetica-boldoblique>,
    :arialblack-italic<helvetica-oblique>,

    :arial<helvetica>,
    :arial-bold<helvetica-bold>,
    :arial-bolditalic<helvetica-boldoblique>,
    :arial-italic<helvetica-oblique>,

    :arialmt<helvetica>,
    :arial-bolditalicmt<helvetica-boldoblique>,
    :arial-boldmt<helvetica-bold>,
    :arial-italicmt<helvetica-oblique>,

    :courier-bolditalic<courier-boldoblique>,
    :courier-italic<courier-oblique>,

    :couriernew<courier>,
    :couriernew-bold<courier-bold>,
    :couriernew-bolditalic<courier-boldoblique>,
    :couriernew-italic<courier-oblique>,

    :couriernewps-bolditalicmt<courier-boldoblique>,
    :couriernewps-boldmt<courier-bold>,
    :couriernewps-italicmt<courier-oblique>,
    :couriernewpsmt<courier>,

    :helvetica-bolditalic<helvetica-boldoblique>,
    :helvetica-italic<helvetica-oblique>,

    :times<times-roman>,
    :timesnewroman<times-roman>,
    :timesnewroman-bold<times-bold>,
    :timesnewroman-bolditalic<times-bolditalic>,
    :timesnewroman-italic<times-italic>,

    :timesnewromanps<times-roman>,
    :timesnewromanps-bold<times-bold>,
    :timesnewromanps-bolditalic<times-bolditalic>,

    :timesnewromanps-bolditalicmt<times-bolditalic>,
    :timesnewromanps-boldmt<times-bold>,
    :timesnewromanps-italic<times-italic>,
    :timesnewromanps-italicmt<times-italic>,

    :timesnewromanpsmt<times-roman>,
    :timesnewromanpsmt-bold<times-bold>,
    :timesnewromanpsmt-bolditalic<times-bolditalic>,
    :timesnewromanpsmt-italic<times-italic>,

    :sans-serif<helvetica>,
    :serif<times-roman>,
    :mono<courier>,

    :symbol-bold<symbol>,
    :symbol-italic<symbol>,
    :symbol-bolditalic<symbol>,

    :webdings<zapfdingbats>,
    :webdings-bold<zapfdingbats>,
    :webdings-italic<zapfdingbats>,
    :webdings-bolditalic<zapfdingbats>,

    :zapfdingbats-bold<zapfdingbats>,
    :zapfdingbats-italic<zapfdingbats>,
    :zapfdingbats-bolditalic<zapfdingbats>,
};

submethod TWEAK(PDF::Content::Font :$!dict) {
    PDF::Content::Font.make-font($_, self)
        with $!dict;
}

#| get a core font name for the given family, weight and style
method core-font-name(Str:D $family!, Str :$weight?, Str :$style?, --> Str) is export(:core-font-name) {
    my Str $face = $family.lc;
    my Str $bold = $weight && $weight ~~ m:i/bold|[6..9]\d\d/
        ?? 'bold' !! '';

    # italic & oblique can be treated as synonyms for core fonts
    my Str $italic = $style && $style ~~ m:i/italic|oblique/
        ?? 'italic' !! '';

    $bold ||= 'bold' if $face ~~ s/ ['-'|',']? bold //;
    $italic ||= $0.lc if $face ~~ s/ ['-'|',']? (italic|oblique) //;

    my Str $sfx = $bold || $italic
        ?? '-' ~ $bold ~ $italic
        !! '';

    $face ~~ s/[['-'|','].*]? $/$sfx/;
    $face = $_ with stdFontMap{$face};
    $face ∈ coreFonts ?? $face !! Nil;
}

our proto method load-font(|c --> ::?CLASS:D) {*};

multi method load-font( Str :$family!, |c) {
    $.load-font( $family, |c );
}

#| get the height of 'X' for the font
multi method height(Numeric $pointsize = UnitsPerEM, Bool :$ex where .so --> Numeric) {
    $!metrics.XHeight * $pointsize / UnitsPerEM;
}

#| compute the overall font-height
multi method height(Numeric $pointsize = UnitsPerEM, Bool :$from-baseline, Bool :$hanging --> Numeric) {
    my List $bbox = $!metrics.FontBBox;
    my Numeric $height = $hanging ?? $!metrics.Ascender !! $bbox[3];
    $height -= $hanging ?? $!metrics.Descender !! $bbox[1]
        unless $from-baseline;
    $height * $pointsize / UnitsPerEM;
}

#| compute the width of a string
method stringwidth(Str $str, $pointsize = 0, Bool :$kern=False --> Numeric) {
    my $glyphs = $!encoder.glyphs;
    $!metrics.stringwidth( $str, $pointsize, :$kern, :$glyphs);
}

#| Core font base encoding: WinAsni, MacRoman or MacExpert
method encoding returns Str {
    my Str %enc-name = :win<WinAnsi>, :mac<MacRoman>, :mac-extra<MacExpert>;
    %enc-name{self.enc};
}

method shape(Str $text) {
    my @shaped;
    my uint8 @cids;
    my $prev-glyph;
    my Hash $wx   = $!metrics.Wx;
    my Hash $kern = $!metrics.KernData;
    my $width = 0;
    my $encoder := $.encoder;

    for $!metrics.ligature-subs($text).ords -> $ord {
        my $glyph-name := $encoder.lookup-glyph($ord);
        next unless $glyph-name && $glyph-name ne '.notdef';
        my uint8 $cid = $encoder.protect: { $encoder.charset{$ord} // $encoder.add-encoding($ord) };

        if $cid {
            $width += $wx{$glyph-name};
            if $prev-glyph {
                if (my $kp := $kern{$prev-glyph}) && (my $kx := $kp{$glyph-name}) {
                    $width += $kx;
                    @shaped.push: $.encode-cids: @cids;
                    @shaped.push: Complex.new(-$kx, 0) ;
                    @cids = ();
                }
            }
            @cids.push: $cid;
        }
        $prev-glyph := $glyph-name;
    }
    @shaped.push($.encode-cids: @cids) if @cids;
    @shaped, $width;
}

sub name(PDF::COS::Name() $name) {
    $name;
}
method !encoding-name {
    name($_ ~ 'Encoding')
        with self.encoding;
}

method !make-dict {
    my $dict = {
        :Type( name 'Font' ), :Subtype( name 'Type1' ),
        :BaseFont( name( $!metrics.FontName ) ),
    };
    $dict<Encoding> = $_ with self!encoding-name;
    $dict;
}

#| produce a PDF Font dictionary for this core font
method to-dict returns PDF::COS::Dict {
    $!encoder.lock.protect: {
        $!dict //= PDF::Content::Font.make-font(
            PDF::COS::Dict.COERCE(self!make-dict),
            self);
    }
}

#| return the font name
method font-name returns Str { $!metrics.FontName }
#| return the underline position for the font
method underline-position returns Numeric { $!metrics.UnderlinePosition }
#| return the underline thickness for the font
method underline-thickness returns Numeric { $!metrics.UnderlineThickness }

method !load-core-font(Str:D $font-name, Cache:D :$cache = $global-cache, |c) is hidden-from-backtrace {
    $cache.core-font: $font-name, self, |c;
}

multi method load-font(Str:D $font-name! where /:i ^[ZapfDingbats|WebDings]/, :$enc='zapf', |c) {
    self!load-core-font('zapfdingbats', :$enc, |c );
}

multi method load-font(Str:D $font-name! where /:i ^Symbol/, :$enc='sym', |c) {
    self!load-core-font('symbol', :$enc, |c );
}

multi method load-font(Str:D $font-name!, :$enc = 'win', Cache:D :$cache = $global-cache, |c) {
    do with $.core-font-name($font-name, |c) {
        self!load-core-font($_, :$enc, :$cache, |c );
    } // self.WHAT;
}

#| PDF Font type (always 'Type1' for core fonts)
method type returns Str  { 'Type1' }
#| whether font is embedded (always False for core fonts)
method is-embedded  returns Bool { False }
#| whether font is subset (always False for core fonts)
method is-subset    returns Bool { False }
#| whether font is a core font (always True for core fonts)
method is-core-font returns Bool { True }

#| finish a PDF rendered font
method cb-finish returns PDF::COS::Dict {
    my $dict := self.to-dict;

    if $!encoder.differences -> $Differences {
        my $Encoding = %(
            :Type( name 'Encoding' ),
            :$Differences,
           );
        $Encoding<BaseEncoding> = $_
            with self!encoding-name;
        $!encoder.protect: {
            $dict<Encoding> = $Encoding;
        }
    }

    $dict;
}

