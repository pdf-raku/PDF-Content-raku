use v6;

class PDF::Basic::CSS::Box {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    class Edge {
	has Numeric ($.top = 0, $.left = 0, $.bottom = 0, $.right = 0);
    }
    has Edge $.padding;
    has Edge $.margin;
    has Numeric $.content-width;
    has Numeric $.content-height;
    has Numeric $.min-width;
    has Numeric $.min-height;
    has Numeric $.max-width;
    has Numeric $.max-height;
    enum BoxSizing <content-box border-box>;
    has BoxSizing $!box-sizing = content-box;

}
