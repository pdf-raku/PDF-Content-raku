use v6;

class PDF::Content::CSS {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    use PDF::Content::CSS::Boxed;
    subset Align of Str where 'left'|'center'|'right'|'justify';
    subset VAlign of Str where 'top'|'center'|'bottom';
    # simple RGB colors at the moment - may change

    use PDF::Content::CSS::Color;
    class Colors does PDF::Content::CSS::Boxed[ PDF::Content::CSS::Color, [0,0,0]] {
    }

    subset Fraction of Numeric where 0.0 .. 1.0;

    subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
    class LineStyles does PDF::Content::CSS::Boxed[LineStyle, 'solid'] {}; 

    subset Length of Numeric;
    use MONKEY-TYPING;

    for List, Array {
        .^add_method( Length.^name, method {
               self[0];
            })
    }
    class Lengths does PDF::Content::CSS::Boxed[Length,0] {};

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
    has PDF::Content::CSS::Color      $.color;
    has PDF::Content::CSS::Color      $.background-color;
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
    has Length     $.line-height;
    has Fraction   $.opacity;
    has LineStyles $.outline-style;
    has Colors     $.outline-color;
    has Lengths    $.padding;
    has VAlign     $.valign;

    method !build-term($term is copy) {
        my role CSSType {
            has Str $.css-type is rw;
        }
        $term = $term.pairs[0] if $term.isa(Hash);
        my $val = $term.value;
        $val does CSSType;
        $val.css-type = $term.key;
        $val;
    }

    method !build-property( Str :$ident!, Array :$expr!, Bool :$important ) {
        my @expr = [ $expr.list.map: { self!build-term($_) } ];
        my %lhs = :@expr;
        %lhs<important> = ? $important;
        $ident => %lhs;
    }

    multi submethod BUILD( Str :$style! ) {
        use CSS::Grammar::CSS3;
        use CSS::Grammar::Actions;
        state $actions //= CSS::Grammar::Actions.new;
        CSS::Grammar::CSS3.parse( $style, :rule<declaration-list>, :$actions )
            or die "unable to parse CSS style declarations: $style";

        my @props = $/.ast.list.map: { self!build-property( |%(.<property>) ) };
        my %opts = @props.sort({.value<important>}). map: { .key => .value<expr> };
        self.BUILD( |%opts );
    }

    multi submethod BUILD(
        Lengths()                 :$!border-width = 0,
        PDF::Content::CSS::Color()  :$!background-color = 'transparent',
        PDF::Content::CSS::Color()  :$!color = 'black',
        LineStyles()              :$!border-style = 'none',
        Length()                  :$!line-height = 1, # normal
        Lengths()                 :$!margin = 0,
        Lengths()                 :$!padding = 0,
        *%other,
    ) {
        self."{.key}"() = .value
            for %other.pairs;
    }

    #| boxed properites e.g. $.border-color-top :== $.border-color.top
    multi method FALLBACK($box-prop where /(.*) '-' (top|right|bottom|left)/, |c)  is rw {
        my Str $prop = ~$0;
        my Str $side = ~$1;
        die "unknown property/method: $box-prop"
            unless self.can($prop);
        self.^add_method( $box-prop, method (|p) is rw {
                                self."$prop"()."$side"(|p);
                            } );
        self."$box-prop"(|c);
    }
    multi method FALLBACK($prop, |c) is default {
        die "unknown property/method: $prop";
    }

}
