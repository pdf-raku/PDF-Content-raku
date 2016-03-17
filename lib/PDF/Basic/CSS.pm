use v6;

class PDF::Basic::CSS {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    class Edges {
	has Numeric ($.top = 0, $.left = 0, $.bottom = 0, $.right = 0);
    }
    has Edges $.padding;
    has Edges $.margin;
    has Numeric $.content-width;
    has Numeric $.content-height;
    has Numeric $.min-width;
    has Numeric $.min-height;
    has Numeric $.max-width;
    has Numeric $.max-height;
    enum BoxSizing <content-box border-box>;
    has BoxSizing $!box-sizing = content-box;

    has Edges $.border-spacing;
    enum LineStyle  is export(:LineStyle) <none hidden dotted dashed solid double groove ridge inset outset>;
    has $.background-color;
    has Numeric $.opacity;
    has LineStyle @.border-style[4] = solid;
    has @.border-color[4];
    has LineStyle @.outline-style[4] = solid;
    has @.outline-color[4];
}
