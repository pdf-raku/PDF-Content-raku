use v6;

use PDF::Basic::CSS;

class PDF::Basic::CSS::Text
    is PDF::Basic::CSS {

    has Str $.font-family;
    enum FontStyle <fs-normal fs-italic fs-oblique>;
    has FontStyle $.font-style = fs-normal;
    # font-weights:
    # normal | bold | bolder | lighter | 100 .. 900
    # just normal, or bold atm
    enum FontWeight <fw-normal fw-bold>;
    has FontWeight $.font-weight = fw-normal;
    has Numeric $.letter-spacing;
    has Numeric $.word-spacing;
    has Numeric $.line-height;
    has Bool $.font-kerning;

    enum TextTransform <capitalize uppercase lowercase t-none>;
    has TextTransform $.text-transform = TextTransform::t-none;

}
