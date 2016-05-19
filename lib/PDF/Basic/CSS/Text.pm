use v6;

use PDF::Basic::CSS;

class PDF::Basic::CSS::Text
    is PDF::Basic::CSS {

    has Str $.font-family;
    subset FontStyle of Str where 'normal'|'italic'|'oblique';
    has FontStyle $.font-style = 'normal';
    # font-weights:
    # 
    # just normal, or bold atm
    subset FontWeight of Str where 'normal'|'bold'|'bolder'|('100'..'900');
    has FontWeight $.font-weight = 'normal';
    has Numeric $.letter-spacing;
    has Numeric $.word-spacing;
    has Numeric $.line-height;
    has Bool $.font-kerning;

    subset TextTransform of Str where 'capitalize'|'uppercase'|'lowercase'|'none';
    has TextTransform $.text-transform = 'none';

}
