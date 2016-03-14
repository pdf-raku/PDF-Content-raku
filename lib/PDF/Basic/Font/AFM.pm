 role PDF::Basic::Font::AFM {

     use PDF::Basic::Font::Encodings;
    has $.enc;
    has $!glyphs;
    has $!encoding;

    method set-encoding( Str :$!enc = 'win') {
	given $!enc {
	    when 'mac' {
		$!glyphs = $PDF::Basic::Font::Encodings::mac-glyphs;
		$!encoding = $PDF::Basic::Font::Encodings::mac-encoding;
	    }
	    when 'win' {
		$!glyphs = $PDF::Basic::Font::Encodings::win-glyphs;
		$!encoding = $PDF::Basic::Font::Encodings::win-encoding;
	    }
	    when 'sym' {
		$!glyphs = $PDF::Basic::Font::Encodings::sym-glyphs;
		$!encoding = $PDF::Basic::Font::Encodings::sym-encoding;
	    }
	    when 'zapf' {
		$!glyphs = $PDF::Basic::Font::Encodings::zapf-glyphs;
		$!encoding = $PDF::Basic::Font::Encodings::zapf-encoding;
	    }
	    default { 
		die ":enc not 'win', 'mac'. 'sym' or 'zapf': $_";
	    }
	}
    }

    #| compute the overall font-height
    method height($pointsize?, Bool :$from-baseline = False) {
	my List $bbox = $.FontBBox;
	my Numeric $height = $bbox[3];
	$height -= $bbox[1] unless $from-baseline;
	$pointsize ?? $height * $pointsize / 1000 !! $height;
    }

    #| reduce string to the displayable characters
    method filter(Str $text-in) {
	$text-in.comb.grep({ $!glyphs{$_}:exists }).join: '';
    }

    #| map ourselves to a PDF::Basic object
    method to-dict {
	my %enc-name = :win<WinAnsiEncoding>, :mac<MacRomanEncoding>;
	my $dict = { :Type( :name<Font> ), :Subtype( :name<Type1> ),
		     :BaseFont( :name( self.FontName ) ),
	};

	if my $name = %enc-name{self.enc} {
	    $dict<Encoding> = :$name;
	}

	$dict;
    }

    method stringwidth(Str $str, Numeric $pointsize=0, Bool :$kern=False) {
	nextwith( $str, $pointsize, :$kern, :$!glyphs);
    }

    multi method encode(Str $s) {
	$s.comb\
	    .map({ $!glyphs{$_} })\
	    .grep( *.defined )\
	    .map({ $!encoding{$_} })\
	    .grep( *.defined )\
	    .Slip;
    }
}
