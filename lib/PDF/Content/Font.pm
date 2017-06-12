use v6;

role PDF::Content::Font {

    use Font::AFM;
    use PDF::Content::Util::Font :Encoded;
    use PDF::Content::Font::AFM;
    use PDF::Content::Font::CMap;
    method from-dict(Hash $font) {
        my subset CoreFontName where
          /^('Times−Roman'|'Helvetica'|'Courier'
             |'Times−Bold'|'Helvetica−Bold'|'Courier−Bold'
             |'Times−Italic'|'Helvetica−Oblique'|'Courier−Oblique'
             |'Times−BoldItalic'|'Helvetica−BoldOblique'|'Courier−BoldOblique'
             |'Symbol'|'ZapfDingbats'
             |[CourierNew|Arial|TimesNewRoman][\,[Bold|Italic|BoldItalic]]?
             )$/;

        my $base-font = PDF::Content::Util::Font::font-name($font<BaseFont>);
        $base-font = 'courier' unless $base-font ~~ CoreFontName;

        my $encoder = do with $font<ToUnicode> -> $cmap {
            # semi stubbed
            PDF::Content::Font::CMap.new: :$cmap;
        }
        else {
            my $enc = do with $font<Encoding> {
                when 'WinAnsiEncoding' { 'win' }
                when 'MacRomanEncoding' { 'mac' }
                when $base-font eq 'Symbol' { 'sym' }
                when $base-font eq 'ZapfDingbats' { 'zapf' }
                default { 'win' }
            }
            PDF::Content::Font::AFM.new: :$enc;
        }
        (Font::AFM.metrics-class( $base-font )
         but Encoded[$encoder]).new;
    }

    has $.font-obj is rw handles <encode decode filter height kern stringwidth>;

}
