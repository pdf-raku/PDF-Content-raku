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
	has Points ($.top = 0, $.left = 0, $.bottom = 0, $.right = 0);
    }

    has Align     $.align;
    has Color     $.background-color;
    has Color     @.border-color[4];
    has Edges     $.border-spacing;
    has LineStyle @.border-style[4] = 'solid';
    has Str       $.box-sizing where 'content-box'|'border-box' = 'content-box';
    has Points    $.content-width;
    has Points    $.content-height;
    has Edges     $.margin;
    has Points    $.max-width;
    has Points    $.max-height;
    has Points    $.min-width;
    has Points    $.min-height;
    has Fraction  $.opacity;
    has LineStyle @.outline-style[4] = 'solid';
    has Color     @.outline-color[4];
    has Edges     @.padding[4];
    has VAlign    $.valign;

}
