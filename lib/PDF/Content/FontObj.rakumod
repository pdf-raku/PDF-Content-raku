#| Interface role for PDF::Content compatible font objects:
unit role PDF::Content::FontObj;

=begin pod
=head2 Description

This role is consumed by font object implmentations, including:

=item PDF::Content::CoreFont

=item  PDF::Font::Loader::FontObj

=end pod

my constant CoreFonts is export(:CoreFonts) = set <
    courier courier-oblique courier-bold courier-boldoblique
    helvetica helvetica-oblique helvetica-bold helvetica-boldoblique
    times-roman times-italic times-bold times-bolditalic
    symbol zapfdingbats
    >;

# font aliases adapted from pdf.js/src/fonts.js
my constant StdFontMap is export(:StdFontMap) = {

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
    $face = $_ with StdFontMap{$face};
    $face ∈ CoreFonts ?? $face !! Nil;
}

method font-name {...}   # font name, including XXXXXX+ prefix for subsetted fonts
method height {...}      # computed font height
method stringwidth {...} # computed with of a string
method encode {...}      # encode text to buffer
method decode {...}      # decode buffer to text
method kern {...}        # kern text
method to-dict {...}     # create a PDF Font dictionary
method cb-finish {...}   # finish the font. e.g. embed and create CMaps and Widths
method type { ... }      # Type0, Type1, Type3, CidFont, CidFont, CIDFontType0, CIDFontType2, MMType1
method is-embedded { ...}

my subset SubsetFontLike of ::?ROLE:D is export(:SubsetFontLike) where { .font-name ~~ m/^<[A..Z]>**6"+"/   }
my subset CoreFontLike of ::?ROLE:D is export(:CoreFontLike) where { .type ~~ 'Type1' && ! .font-descriptor.defined && .core-font-name(.font-name).defined }
method is-subset { so (self ~~ SubsetFontLike)  }
method is-core-font { so (self ~~ CoreFontLike) }

# todo: underline-position underline-thickness lock encoding encode-cids units-per-EM shape
