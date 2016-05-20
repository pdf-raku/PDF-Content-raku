use v6;

class PDF::Basic::CSS {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    subset Align of Str where 'left'|'center'|'right'|'justify';
    subset VAlign of Str where 'top'|'center'|'bottom';
    # simple RGB colors at the moment - may change
    subset ColorChannel of Int where 0 .. 0xFF;
    subset Color of Array where .elems == 3 && all(.list) ~~ ColorChannel;
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

    augment class Str {
        #| coerce color term to ab rgb value
        method PDF::Basic::CSS::Color() returns Color {
            # todo use CSS::Module - which has a better understanding of colors
            use CSS::Grammar::AST;
            use CSS::Grammar::Actions;
            use CSS::Grammar::CSS3;
            my Color $rgb;
            state $actions //= CSS::Grammar::Actions.new;
            my Pair $term;

            my $p = CSS::Grammar::CSS3.parse(self, :rule<term>, :$actions);

            with $p {
                $term = $p.ast;
            }
            else {
                die "unable to parse color: {self.perl}";
            }
        
            given $term.key {
                when 'rgb' {
                    # color function or mask. some examples:
                    #   rgb(127,0,0) rgb(100%, 10%, 0%)
                    #   #FF0000 #f00
                    $rgb = [ $term.value.map: *.<num> ];
                }
                when 'ident' { # color name .e.g: 'red'
                    $rgb = %CSS::Grammar::AST::CSS3-Colors{ $term.value }
                        // die "unknown color name: {self}";
                }
                default {
                    die "unable to parse color: {self.perl}";
                }
            }
            $rgb;
        }
    }

    augment class Hash {
        method PDF::Basic::CSS::Edges() {
            Edges.new( |self );
        }
    }

    augment class Array {
        method PDF::Basic::CSS::Color() {
            die "not a valid Color array: {self.perl}"
                unless self ~~ Color;
            self
        }
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

    submethod BUILD(
        Edges() :$!border-width = Nil,
        Color() :$!background-color = Nil,
    ) {
    }

}
