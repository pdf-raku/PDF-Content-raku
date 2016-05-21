use v6;

class PDF::Basic::CSS {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    use PDF::Basic::CSS::Boxed;
    subset Align of Str where 'left'|'center'|'right'|'justify';
    subset VAlign of Str where 'top'|'center'|'bottom';
    # simple RGB colors at the moment - may change

    use PDF::Basic::CSS::Color;
    class Colors does PDF::Basic::CSS::Boxed[ PDF::Basic::CSS::Color, [0,0,0]] {
    }

    subset Fraction of Numeric where 0.0 .. 1.0;

    subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
    class LineStyles does PDF::Basic::CSS::Boxed[LineStyle, 'solid'] {}; 

    subset Length of Numeric;
    class Lengths does PDF::Basic::CSS::Boxed[Length,0] {};

    # COMPOSE phasers are NYI https://doc.perl6.org/language/phasers#COMPOSE
    # call manually for classes that do the Boxed role
    .COMPOSE for Colors, LineStyles, Lengths;

    #`{{  The CSS Box model in a nut-shell

                           --------------- <-- top
                             top margin
                           ---------------
                             top border
                           ---------------
                            top padding
                           +-------------+ <-- inner top
|        |        |        |             |         |         |         |
|--left--|--left--|--left--|-- content --|--right--|--right--|--right--|
| margin | border | padding|             | padding | border  | margin  |
|        |        |        |             |         |         |         |
                           +-------------+ <-- inner bottom
^                          ^             ^                             ^
left         left inner edge             right inner edge          right
outer                                                              outer
edge                        bottom padding                          edge
                           ---------------
                             bottom border
                           ---------------
                             bottom margin
                           --------------- <-- bottom

    #  diagram from https://www.w3.org/TR/2008/REC-CSS1-20080411/
    #  }}

    has Align      $.align;
    has PDF::Basic::CSS::Color      $.background-color;
    has Colors     $.border-color;
    has Lengths    $.border-width;
    has LineStyles $.border-style;
    has Lengths    $.margin;
    has Str        $.box-sizing where 'content-box'|'border-box' = 'content-box';
    has Length     $.content-width;
    has Length     $.content-height;
    has Length     $.max-width;
    has Length     $.max-height;
    has Length     $.min-width;
    has Length     $.min-height;
    has Fraction   $.opacity;
    has LineStyles $.outline-style;
    has Colors     $.outline-color;
    has Lengths    $.padding;
    has VAlign     $.valign;

    submethod BUILD(
        Lengths()                 :$!border-width = 0,
        PDF::Basic::CSS::Color()  :$!background-color = 'transparent',
        LineStyles()              :$!border-style = 'none',
        Lengths()                 :$!margin = 0,
        Lengths()                 :$!padding = 0,
        *%other,
    ) {
        self."{.key}"() = .value
            for %other.pairs;
    }

    #| e.g. $.border-color-top :== $.border-color.top
    method FALLBACK($sub-prop where /(.*) '-' (top|right|bottom|left)/, |c)  is rw {
        my Str $prop = ~$0;
        my Str $side = ~$1;
        self.^add_method( $sub-prop, method (|p) is rw {
                                self."$prop"()."$side"(|p);
                            } );
        self."$sub-prop"(|c);
    }


}
