use v6;

role PDF::Content::Font {

    use PDF::Content::Util::Font;
    method from-dict(Hash $font) {
        my subset CoreFont of Hash where {
          .<Subtype> ~~ 'Type1'
          and
          .<BaseFont>  ~~ /'Times−Roman'|'Helvetica'|'Courier'
                          |'Times−Bold'|'Helvetica−Bold'|'Courier−Bold'
                          |'Times−Italic'|'Helvetica−Oblique'|'Courier−Oblique'
                          |'Times−BoldItalic'|'Helvetica−BoldOblique'|'Courier−BoldOblique'
                          |'Symbol'|'ZapfDingbats'
                          |[CourierNew|Arial|TimesNewRoman][\,[Bold|Italic|BoldItalic]]?/
       };

        my %opt;
        with $font<Encoding> {
            when 'WinAnsiEncoding' { %opt<enc> = 'win' }
            when 'MacRomanEncoding' { %opt<enc> = 'mac' }
        }
        if $font ~~ CoreFont {
            PDF::Content::Util::Font::core-font( $font<BaseFont>, |%opt);
        }
        else {
            # substitute
            PDF::Content::Util::Font::core-font('courier', |%opt);
        }

    }

    has $.font-obj is rw handles <encode decode filter height kern stringwidth>;

}
