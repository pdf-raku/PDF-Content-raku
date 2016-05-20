use v6;

class PDF::Basic::CSS {
    # See:
    # - https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Introduction_to_the_CSS_box_model
    # - https://www.w3.org/TR/CSS21/visudet.html#containing-block-details
    use PDF::Basic::CSS::Boxed;
    subset Align of Str where 'left'|'center'|'right'|'justify';
    subset VAlign of Str where 'top'|'center'|'bottom';
    # simple RGB colors at the moment - may change

    use CSS::Grammar::AST;
    subset ColorName of Str where %CSS::Grammar::AST::CSS3-Colors{$_}:exists;
    subset ColorChannel of Int where 0 .. 0xFF;
    subset Color of Array where .elems == 3 && all(.list) ~~ ColorChannel;
    class Colors does PDF::Basic::CSS::Boxed[Color, [0,0,0]] {
        use MONKEY-TYPING;
        augment class Str {
            #| coerce color term to ab rgb value
            method PDF::Basic::CSS::Color() returns Color {
                # todo use CSS::Module - which has a better understanding of colors
                use CSS::Grammar::Actions;
                use CSS::Grammar::CSS3;
                my Color $color;
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
                        $color = [ $term.value.map: *.<num> ];
                    }
                    when 'ident' { # color name .e.g: 'red'                                                                             
                        $color = %CSS::Grammar::AST::CSS3-Colors{ $term.value }
                        // die "unknown color name: {self}";
                    }
                    default {
                        die "unknown color: self";
                    }
                }
                $color;
            }
        }
    }

    subset Fraction of Numeric where 0.0 .. 1.0;

    subset LineStyle of Str where 'none'|'hidden'|'dotted'|'dashed'|'solid'|'double'|'groove'|'ridge'|'inset'|'outset';
    class LineStyles does PDF::Basic::CSS::Boxed[LineStyle, 'solid'] {}; 

    subset Length of Numeric;
    class Lengths does PDF::Basic::CSS::Boxed[Length,0] {};

    # COMPOSE phasers are NYI https://doc.perl6.org/language/phasers#COMPOSE
    # call manually for classes that do the Boxed role
    .COMPOSE for Colors, LineStyles, Lengths;

    has Align      $.align;
    has Color      $.background-color;
    has Colors     $.border-color;
    has Lengths    $.border-spacing;
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
        Lengths()    :$!border-width = Nil,
        Color()      :$!background-color = Nil,
        LineStyles() :$!border-style = Nil,
    ) {
    }

}
