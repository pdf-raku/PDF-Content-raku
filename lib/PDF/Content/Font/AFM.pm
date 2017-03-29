role PDF::Content::Font::AFM {

    use PDF::Content::Font::Encodings;
    my subset EncodingStr of Str where 'mac'|'win'|'sym'|'zapf';
    has $.enc = 'win';
    has $!glyphs = $PDF::Content::Font::Encodings::win-glyphs;
    has $!encoding = $PDF::Content::Font::Encodings::mac-encoding;
    has str @char-map;

    submethod set-encoding( EncodingStr :$!enc = 'win') {
	given $!enc {
	    when 'mac' {
		$!glyphs = $PDF::Content::Font::Encodings::mac-glyphs;
		$!encoding = $PDF::Content::Font::Encodings::mac-encoding;
	    }
	    when 'win' {
		$!glyphs = $PDF::Content::Font::Encodings::win-glyphs;
		$!encoding = $PDF::Content::Font::Encodings::win-encoding;
	    }
	    when 'sym' {
		$!glyphs = $PDF::Content::Font::Encodings::sym-glyphs;
		$!encoding = $PDF::Content::Font::Encodings::sym-encoding;
	    }
	    when 'zapf' {
		$!glyphs = $PDF::Content::Font::Encodings::zapf-glyphs;
		$!encoding = $PDF::Content::Font::Encodings::zapf-encoding;
	    }
	}
        for $!glyphs.pairs {
            @!char-map[.key.ord] = $!encoding{.value};
        }
    }

    #| compute the overall font-height
    method height($pointsize?, Bool :$from-baseline, Bool :$hanging) {
	my List $bbox = $.FontBBox;
	my Numeric $height = $bbox[3];
        $height *= .75 if $hanging;  # not applicable to core fonts - approximate
	$height -= $bbox[1] unless $from-baseline;
	$pointsize ?? $height * $pointsize / 1000 !! $height;
    }

    #| reduce string to the displayable characters
    method filter(Str $text-in) {
	$text-in.order.grep({ @!char-map[$_] }).join;
    }

    #| map ourselves to a PDF::Content object
    method to-dict {
	my %enc-name = :win<WinAnsiEncoding>, :mac<MacRomanEncoding>;
	my $dict = { :Type( :name<Font> ), :Subtype( :name<Type1> ),
		     :BaseFont( :name( self.FontName ) ),
	};

	with %enc-name{self.enc} -> $name {
	    $dict<Encoding> = :$name;
	}

	$dict;
    }

    method stringwidth(Str $str, Numeric $pointsize=0, Bool :$kern=False) {
	nextwith( $str, $pointsize, :$kern, :$!glyphs);
    }


    method encode(Str $s) {
        $s.ords.map({@!char-map[$_]}).grep: {$_};
    }

}
