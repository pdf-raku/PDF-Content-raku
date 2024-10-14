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
                    my Font::AFM $metrics .= core-font( $font-name );
                    my Str %glyphs = $font-name eq 'zapfdingbats'
                                      ?? %$zapf-glyphs
                                      !! $metrics.Wx.keys.map: {%CharSet{$_} => $_ };
                    $metrics.glyphs = %glyphs;
                    my $encoder = PDF::Content::Font::Enc::Type1.new: :$enc, :%glyphs;
                    $class.new( :$encoder, :$metrics, :$dict, |c);
            }
        }
    }
}
my Cache $global-cache .= new;

submethod TWEAK(PDF::Content::Font :$!dict) {
    PDF::Content::Font.make-font($_, self)
        with $!dict;
}

our proto method load-font(|c --> ::?CLASS:D) {*};

multi method load-font( Str :$family!, |c) {
    $.load-font( $family, |c );
}

#| get the height of 'X' for the font
multi method height(Numeric $pointsize = UnitsPerEM, Bool :$ex! where .so --> Numeric) {
    $!metrics.XHeight * $pointsize / UnitsPerEM;
}

#| compute the overall font-height
multi method height(Numeric $pointsize = UnitsPerEM, Bool :$from-baseline, Bool :$hanging --> Numeric) {
    my List $bbox = $!metrics.FontBBox;
    my Numeric $height = $!metrics.Ascender
        if $hanging;
    $height //= $bbox[3];
    unless $from-baseline {
        my Numeric $descent = $!metrics.Descender
            if $hanging;
        $descent //= $bbox[1];
        $height -= $descent;
    }
    $height * $pointsize / UnitsPerEM;
}

#| compute the width of a string
method stringwidth(Str $str, $pointsize = 0, Bool :$kern=False --> Numeric) {
    $!metrics.stringwidth( $str, $pointsize, :$kern);
}

#| Core font base encoding: WinAnsi, MacRoman or MacExpert
method encoding returns Str {
    my Str %enc-name = :win<WinAnsi>, :mac<MacRoman>, :mac-extra<MacExpert>;
    %enc-name{self.enc};
}

method shape(Str $text, Bool :$kern = True) {
    my @shaped;
    my uint8 @cids;
    my $prev-glyph;
    my Hash $wx   = $!metrics.Wx;
    my Hash $kern-data = $!metrics.KernData if $kern;
    my $width = 0;
    my $encoder := $.encoder;

    for $!metrics.ligature-subs($text).ords -> $ord {
        my $glyph-name := $encoder.lookup-glyph($ord);
        next unless $glyph-name && $glyph-name ne '.notdef';
        my uint8 $cid = $encoder.protect: { $encoder.charset{$ord} // $encoder.add-encoding($ord) };

        if $cid {
            $width += $wx{$glyph-name};
            if $kern && $prev-glyph {
                if (my $kp := $kern-data{$prev-glyph}) && (my $kx := $kp{$glyph-name}) {
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

