use v6;

module PDF::Content::Util::Font {
    use Font::AFM:ver(v1.23.5..*);
    use PDF::Content::Font::AFM;
    # font aliases adapted from pdf.js/src/fonts.js
    BEGIN constant stdFontMap = {

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
    };

    our sub font-name(Str $family! is copy, Str :$weight?, Str :$style?, ) {
        my Str $bold = $weight && $weight ~~ m:i/bold|[6..9]00/
            ?? 'bold' !! '';

        # italic & oblique can be treated as synonyms for core fonts
        my Str $italic = $style && $style ~~ m:i/italic|oblique/
            ?? 'italic' !! '';

        $bold ||= 'bold' if $family ~~ s/:i:s ['-'|',']? bold //;
        $italic ||= $0.lc if $family ~~ s/:i:s ['-'|',']? (italic|oblique) //;

        my Str $sfx = $bold || $italic
            ?? '-' ~ $bold ~ $italic
            !! '';

       $family.subst(/['-'.*]? $/, $sfx );
    }

    our proto sub core-font(|c) {*};

    multi sub core-font( Str :$family!, |c) {
        my Str $font-name = font-name($family, |c);
        core-font( $font-name, |c );
    }

    role Encoded[$encoder] is export(:Encoded) {
        method enc { $encoder.enc }
        method encode(|c) { $encoder.encode(|c) }
        method decode(|c) { $encoder.decode(|c) }
        method filter($s) { $encoder.filter($s); }
        method to-dict    { $encoder.to-dict(self.FontName) }
        method height(|c) {
            my List $bbox = $.FontBBox;
            $encoder.height(:$bbox, |c);
        }
        method stringwidth(Str $str, Numeric $pointsize=0, Bool :$kern=False) {
            my $glyphs = $encoder.glyphs;
            nextwith( $str, $pointsize, :$kern, :$glyphs);
        }

    }

    sub load-core-font($font-name, :$enc!) {
        state %core-font-cache;
        %core-font-cache{$font-name.lc~'-*-'~$enc} //= do {
            my $encoder = PDF::Content::Font::AFM.new: :$enc;
            (Font::AFM.metrics-class( $font-name )
             but Encoded[$encoder]).new;
        }
    }

    multi sub core-font(Str $font-name! where { $font-name ~~ m:i/^[ZapfDingbats|WebDings]/ }, :$enc='zapf') {
        load-core-font('zapfdingbats', :$enc );
    }

    multi sub core-font(Str $font-name! where { $font-name ~~ m:i/^Symbol/ }, :$enc='sym') {
        load-core-font('symbol', :$enc );
    }

    multi sub core-font(Str $font-name! is copy, :$enc = 'win', |c) is default {
        $font-name = $font-name.subst(',','-').lc;
        $font-name = $_ with stdFontMap{$font-name};
        load-core-font( $font-name, :$enc );
    }

}
