use v6;

role PDF::Content::Font {
    use PDF::COS;
    use PDF::COS::Dict;
## use PDF::Content::FontObj;
    has ## PDF::Content::FontObj
    $.font-obj is rw handles <encode decode filter font-name height kern stringwidth>;

    method make-font(PDF::COS::Dict:D $font-dict, $font-obj) {
        $font-dict.^mixin: PDF::Content::Font
            unless $font-dict.does(PDF::Content::Font);
        $font-dict.set-font-obj($font-obj);
        $font-dict;
    }
    # needed by PDF::Class (PDF::Font::Type1)
    method set-font-obj($!font-obj) { $!font-obj }

    method cb-finish { .?cb-finish with $!font-obj }
}
