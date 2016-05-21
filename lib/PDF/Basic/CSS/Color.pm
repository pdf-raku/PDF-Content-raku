use v6;
use CSS::Grammar::AST;
class PDF::Basic::CSS::Color {
    subset ColorName of Str where %CSS::Grammar::AST::CSS3-Colors{$_}:exists;
    subset ColorChannel of Int where 0 .. 0xFF;
    subset AlphaChannel of Rat where 0 .. 1.0;
    has ColorChannel @.rgb[3] is required;
    has AlphaChannel $.alpha = 1.0;
    method Str {
        join [~] '#', @!rgb.map: { sprintf '%02x', ($_ * $!alpha).round };
    }
    method Array {
        [ @!rgb.map: { ($_ * $!alpha).round } ];
    }
    use MONKEY-TYPING;
    augment class Array {
        method PDF::Basic::CSS::Color() returns PDF::Basic::CSS::Color {
            PDF::Basic::CSS::Color.new( :rgb(self) );
        }
    }
    augment class Str {
        #| coerce color term to an rgb value
        method PDF::Basic::CSS::Color() returns PDF::Basic::CSS::Color {
            # todo use CSS::Module - which has a better understanding of colors
            use CSS::Grammar::Actions;
            use CSS::Grammar::CSS3;
            state $actions //= CSS::Grammar::Actions.new;
            my Pair $term;

            my $p = CSS::Grammar::CSS3.parse(self, :rule<term>, :$actions);

            with $p {
                $term = $p.ast;
            }
            else {
                die "unable to parse color: {self.perl}";
            }

            my ($alpha, $rgb) = do given $term.key {
                when 'rgb' {
                    # color function or mask. some examples:
                    #   rgb(127,0,0) rgb(100%, 10%, 0%)
                    #   #FF0000 #f00
                    1.0, [ $term.value.map: *.<num> ];
                }
                when 'ident' { # color name .e.g: 'red'
                    given $term.value {
                        when 'transparent' {
                            0.0, [255 xx 3]
                        }
                        default {
                            1.0, %CSS::Grammar::AST::CSS3-Colors{ $_ }
                            // die "unknown color name: {self}"
                        }
                    }
                }
                default {
                    die "unknown color: self";
                }
            }
            PDF::Basic::CSS::Color.new( :rgb($rgb.list), :$alpha );
        }
    }
}
