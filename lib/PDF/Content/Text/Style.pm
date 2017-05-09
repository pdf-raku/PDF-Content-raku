use v6;

class PDF::Content::Text::Style {
    has         $.font is rw is required;
    has Numeric $.font-size is rw = 16;
    has Numeric $.leading is rw = 1.1;
    my subset Alignment of Str is export(:Alignment) where 'left'|'center'|'right'|'justify';
    has Alignment $.align = 'left';
    my subset VerticalAlignment of Str is export(:VerticalAlignment) where 'top'|'center'|'bottom';
    has VerticalAlignment $.valign = 'top';
    has Bool $.kern;
    has Numeric $.space-width = $!font.stringwidth(' ', $!font-size );

    # directly mapped to graphics state
    has Numeric $.WordSpacing;
    has Numeric $.CharSpacing;
    has Numeric $.HorizScaling;
    has Numeric $.TextRise;

    my subset Baseline of Str is export(:BaseLine) where { !.defined || $_ eq 'alphabetic'|'top'|'bottom'|'middle'|'ideographic'|'hanging' };

    multi submethod TWEAK(:$gfx, Baseline :$baseline) is default {
        $!CharSpacing  //= do with $gfx {.CharSpacing}  else {0.0};
	$!WordSpacing  //= do with $gfx {.WordSpacing}  else {0.0};
	$!HorizScaling //= do with $gfx {.HorizScaling} else {100};
	$!TextRise     //= do with $baseline {
	    - self!baseline($_);
	} else {
	    with $gfx {.TextRise} else {0.0};
	}
    }

    method !baseline($_) {
	when 'alphabetic'  { 0 }
	when 'top'         { $!font.height( $!font-size, :from-baseline); }
	when 'bottom'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size) }
	when 'middle'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size)/2 }
	when 'ideographic' { $!font.height( $!font-size, :from-baseline) - $!font-size; }
	when 'hanging'     { $!font.height( $!font-size, :from-baseline, :hanging) }
	default            { 0 }
    }
}
