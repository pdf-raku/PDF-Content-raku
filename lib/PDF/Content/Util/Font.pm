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

        :symbol-bold<symbol>,
        :symbol-bolditalic<symbol>,
        :symbol-italic<symbol>,

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

    our proto sub core-font(|c) {*};

    multi sub core-font( Str :$family! is copy, Str :$weight?, Str :$style?, |c) {

        my Str $bold = $weight && $weight ~~ m:i/bold|[6..9]00/
            ?? 'bold' !! '';

        # italic & oblique can be treated as synonyms for core fonts
        my Str $italic = $style && $style ~~ m:i/italic|oblique/
            ?? 'italic' !! '';

        $bold ||= 'bold' if $family ~~ s/:i:s '-'? bold //;
        $italic ||= $0.lc if $family ~~ s/:i:s '-'? (italic|oblique) //;

        my Str $sfx = $bold || $italic
            ?? '-' ~ $bold ~ $italic
            !! '';

        my Str $font-name = $family.subst(/['-'.*]? $/, $sfx );

        core-font( $font-name, |c );
    }

    sub load-core-font($font-name, :$enc!) {
        state %core-font-cache;
        %core-font-cache{$font-name.lc~'-*-'~$enc} //= do {
            my \font = (Font::AFM.metrics-class( $font-name )
                        but PDF::Content::Font::AFM).new(:$enc);
            font.set-encoding(:$enc);
            font;
        }
    }

    multi sub core-font(Str $font-name! where { $font-name ~~ m:i/^ ZapfDingbats $/ }) {
        load-core-font( $font-name.lc, :enc<zapf> );
    }

    multi sub core-font(Str $font-name! where { $font-name ~~ m:i/^ Symbol $/ }) {
        load-core-font( $font-name.lc, :enc<sym> );
    }

    multi sub core-font(Str $font-name! where { stdFontMap{$font-name.lc}:exists }, |c) {
        core-font( stdFontMap{$font-name.lc}, |c );
    }

    multi sub core-font(Str $font-name!, :$enc = 'win') is default {
        load-core-font( $font-name.lc, :$enc );
    }

}
