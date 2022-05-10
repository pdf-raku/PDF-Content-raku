use PDF::Content::FontObj;

class PDF::Content::Font::CoreFont
    does PDF::Content::FontObj {
    use Font::AFM:ver(v1.23.5+);
    use PDF::Content::Font;
    use PDF::Content::Font::Enc::Type1;
    use PDF::COS::Dict;
    use PDF::COS::Name;

    has Font::AFM $.metrics handles <kern>;
    has PDF::Content::Font::Enc::Type1 $.encoder handles <encode decode enc>;
    has PDF::Content::Font $!dict;
    class Cache {
        has Lock $!lock .= new;
        has %!fonts;
        method core-font(Str:D $font-name, PDF::Content::Font::CoreFont $class?, :$enc!, |c) {
            $!lock.protect: {
                %!fonts{$font-name.lc~'-*-'~$enc} //= do {
                    my $encoder = PDF::Content::Font::Enc::Type1.new: :$enc;
                    my $metrics = Font::AFM.core-font( $font-name );
                    $class.new( :$encoder, :$metrics, |c);
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

    method core-font-name(Str:D $family!, Str :$weight?, Str :$style?, ) is export(:core-font-name) {
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

    our proto method load-font(|c) {*};

    multi method load-font( Str :$family!, |c) {
        $.load-font( $family, |c );
    }

    multi method height(Numeric $pointsize?, Bool :$ex where .so) {
        my Numeric $height = $!metrics.XHeight;
	$pointsize ?? $height * $pointsize / 1000 !! $height;
    }

    #| compute the overall font-height
    multi method height(Numeric $pointsize?, Bool :$from-baseline, Bool :$hanging) {
        my List $bbox = $!metrics.FontBBox;
	my Numeric $height = $hanging ?? $!metrics.Ascender !! $bbox[3];
	$height -= $hanging ?? $!metrics.Descender !! $bbox[1]
            unless $from-baseline;
	$pointsize ?? $height * $pointsize / 1000 !! $height;
    }

    method stringwidth(Str $str, $pointsize = 0, Bool :$kern=False) {
        my $glyphs = $!encoder.glyphs;
        $!metrics.stringwidth( $str, $pointsize, :$kern, :$glyphs);
    }

    method !encoding-name {
        my %enc-name = :win<WinAnsiEncoding>, :mac<MacRomanEncoding>, :mac-extra<MacExpertEncoding>;
        with %enc-name{self.enc} -> $name {
            :$name;
        }
    }

    method !make-dict {
        my $dict = {
            :Type( :name<Font> ), :Subtype( :name<Type1> ),
            :BaseFont( :name( $!metrics.FontName ) ),
        };
        $dict<Encoding> = $_ with self!encoding-name;
        $dict;
    }

    method to-dict {
        $!encoder.lock.protect: {
            $!dict //= PDF::Content::Font.make-font(
                PDF::COS::Dict.COERCE(self!make-dict),
                self);
        }
    }

    method font-name { $!metrics.FontName }
    method underline-position  { $!metrics.UnderlinePosition }
    method underline-thickness { $!metrics.UnderlineThickness }

    method !load-core-font(Str:D $font-name, Cache:D :$cache = $global-cache, |c) is hidden-from-backtrace {
        $cache.core-font: $font-name, self, |c;
    }

    multi method load-font(Str:D $font-name! where /:i ^[ZapfDingbats|WebDings]/, :$enc='zapf', |c) {
        self!load-core-font('zapfdingbats', :$enc, |c );
    }

    multi method load-font(Str:D $font-name! where /:i ^Symbol/, :$enc='sym', |c) {
        self!load-core-font('symbol', :$enc, |c );
    }

    multi method load-font(Str:D $font-name!, :$enc = 'win',  Cache:D :$cache = $global-cache, |c) {
        do with $.core-font-name($font-name, |c) {
            self!load-core-font($_, :$enc, :$cache );
        } // self.WHAT;
    }

    method is-embedded  { False }
    method is-subset    { False }
    method is-core-font { True }

    method cb-finish {
        my $dict := self.to-dict;

        if $!encoder.differences -> $Differences {
            my $Encoding = %(
                :Type( :name<Encoding> ),
                :$Differences,
               );
            $Encoding<BaseEncoding> = $_
                with self!encoding-name;

            $dict<Encoding> = $Encoding;
        }

        $dict;
    }
}
