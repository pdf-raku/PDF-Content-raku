use v6;

class PDF::Basic::CSS {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    subset Align of Str where 'left'|'center'|'right'|'justify';
    subset VAlign of Str where 'top'|'center'|'bottom';
    subset Color of Any; # not sure how to type these yet
    subset Fraction of Numeric where 0.0 .. 1.0;
    subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
    subset Points of Numeric;
    class Edges {
	has Points ($.top, $.left, $.bottom, $.right);
        submethod BUILD(:$!top = 0,
                        :$!right = $!top,
                        :$!bottom = $!top,
                        :$!left = $!right) {
        }
    }

    use MONKEY-TYPING;

    augment class Hash {
        method PDF::Basic::CSS::Edges() {
            Edges.new( |self );
        }
    }

    augment class Array {
        method PDF::Basic::CSS::Edges() {
            my %box;
            %box<top>     = $_ with self[0];
            %box<right>   = $_ with self[1];
            %box<bottom>  = $_ with self[2];
            %box<left>    = $_ with self[3];
            Edges.new( |%box );
        }
    }

    augment class Rat {
        method PDF::Basic::CSS::Edges() {
            Edges.new( :top(self) );
        }
    }

    has Align     $.align;
    has Color     $.background-color;
    has Color     @.border-color[4];
    has Edges     $.border-spacing;
    has Edges     $.border-width;
    has LineStyle @.border-style[4] = 'solid' xx 4;
    has Str       $.box-sizing where 'content-box'|'border-box' = 'content-box';
    has Points    $.content-width;
    has Points    $.content-height;
    has Edges     $.margin;
    has Points    $.max-width;
    has Points    $.max-height;
    has Points    $.min-width;
    has Points    $.min-height;
    has Fraction  $.opacity;
    has LineStyle @.outline-style[4] = 'solid' xx 4;
    has Color     @.outline-color[4];
    has Edges     @.padding[4];
    has VAlign    $.valign;

    submethod BUILD(Edges() :$!border-width) {
    }

}
