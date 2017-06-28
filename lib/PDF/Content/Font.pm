use v6;

role PDF::Content::Font {

    use Font::AFM;
    use PDF::Content::Util::Font :Encoded;
    use PDF::Content::Font::AFM;
    use PDF::Content::Font::CMap;
    method from-dict(Hash $font) {

        my $base-font = PDF::Content::Util::Font::core-font-name($font<BaseFont>)
            // 'courier';

        my $encoder = do with $font<ToUnicode> -> $cmap {
            # semi stubbed
            PDF::Content::Font::CMap.new: :$cmap;
        }
        else {
            my $enc = do given $font<Encoding> {
                when 'WinAnsiEncoding' { 'win' }
                when 'MacRomanEncoding' { 'mac' }
                when $base-font ~~ /^symbol/ { 'sym' }
                when $base-font ~~ /^zapfdingbats/ { 'zapf' }
                default { 'std' }
            }
            PDF::Content::Font::AFM.new: :$enc;
        }
        (Font::AFM.metrics-class( $base-font )
         but Encoded[$encoder]).new;
    }

    has $.font-obj is rw handles <encode decode filter height kern stringwidth>;

}
