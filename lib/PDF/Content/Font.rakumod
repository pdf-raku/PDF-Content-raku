#| Font handling for font dictionaries
unit role PDF::Content::Font;

use PDF::COS;
use PDF::COS::Dict;
use PDF::Content::FontObj;
#| font object associated with this font dictionary
has PDF::Content::FontObj $.font-obj is rw handles <encode decode encode-cids protect filter font-name height kern stringwidth underline-position underline-thickness units-per-EM shape>;

#| associate this font dictionary with a font object
multi method make-font(PDF::Content::Font() $_, PDF::Content::FontObj:D $font-obj) {
    .make-font($font-obj);
}
multi method make-font(::?ROLE:D: PDF::Content::FontObj:D $!font-obj) {
    self;
}
method cb-finish {
    with $!font-obj {.cb-finish } else { self };
}

multi method COERCE(::?ROLE $_) { $_ }
multi method COERCE(PDF::COS::Dict:D() $_ where .<Type> ~~ 'Font') {
    .^mixin: ::?ROLE;
}
