use v6;

class PDF::Content::Text::Style {
    has         $.font is rw is required;
    has Numeric $.font-size is rw = 16;
    has Numeric $.leading is rw = 1.1;
    my subset Baseline of Str is export(:BaseLine) where 'alphabetic'|'top'|'bottom'|'middle'|'ideographic'|'hanging';
    has Baseline $.baseline is rw = 'alphabetic';
    my subset Alignment of Str is export(:Alignment) where 'left'|'center'|'right'|'justify';
    has Alignment $.align = 'left';
    my subset VerticalAlignment of Str is export(:VerticalAlignment) where 'top'|'center'|'bottom';
    has VerticalAlignment $.valign = 'top';
    has Bool $.kern;
    has Numeric $.space-width = $!font.stringwidth(' ', $!font-size );

    method text-rise {
        given $!baseline {
            when 'alphabetic'  { 0 }
            when 'top'         { $!font.height( $!font-size, :from-baseline); }
            when 'bottom'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size) }
            when 'middle'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size)/2 }
            when 'ideographic' { $!font.height( $!font-size, :from-baseline) - $!font-size; }
            when 'hanging'     { $!font.height( $!font-size, :from-baseline, :hanging) }
        }

    }
}
