#| Implements a Type-1 single byte font encoding scheme.
#| it optimises the encoding to accomodate any subset of
#| <= 255 unique glyphs; by (1) using the standard
#| encoding for the glyph (2) mapping codes that are not
#| used in the encoding scheme, or (3) re-allocating codes
#| that have not been used.
class PDF::Content::Font::Enc::Type1 {
    use PDF::Content::Font::Enc::Glyphic;
    also does PDF::Content::Font::Enc::Glyphic;

    use PDF::Content::Font::Encoder;
    also does PDF::Content::Font::Encoder;

    use PDF::Content::Font::Encodings :mac-encoding, :win-encoding, :sym-encoding, :std-encoding, :zapf-encoding, :mac-extra-encoding;
    has UInt %!from-unicode{UInt};  #| all encoding mappings
    has UInt %.charset{UInt}; #| used characters (useful for subsetting)
    has uint16 @.to-unicode[256];
    has uint8 @!spare-cids;   #| unmapped codes in the encoding scheme
    my subset Type1EncodingScheme of Str is export(:Type1EncodingScheme) where 'mac'|'win'|'sym'|'zapf'|'std'|'mac-extra';
    has Lock $.lock handles<protect> .= new;
    has Type1EncodingScheme $.enc = 'win';
    my constant %Encoding = %(
        :mac($mac-encoding),   :win($win-encoding),
        :sym($sym-encoding),   :std($std-encoding),
        :mac-extra($mac-extra-encoding),
        :zapf($zapf-encoding),
    );

    submethod TWEAK {
        my array $encoding = %Encoding{$!enc};

        @!to-unicode = $encoding.list;
        my uint16 @allocated-cids;
        for 1 .. 255 -> $cid {
            if @!to-unicode[$cid] -> uint16 $ord {
                %!from-unicode{$ord} = $cid;
                # CID used in this encoding schema. reallocate as a last resort
                @allocated-cids.unshift: $cid;
            }
            else {
                # spare CID use it first
                @!spare-cids.push($cid)
            }
        }
        # also keep track of codes that are allocated in the encoding scheme, but
        # have not been used in this encoding instance's charset. These can potentially
        # be remapped via differences to squeeze the most out of our 8-bit encoding scheme.
        @!spare-cids.append: @allocated-cids;
        # map non-breaking space to a regular space
        %!from-unicode{"\c[NO-BREAK SPACE]".ord} //= %!from-unicode{' '.ord};
    }

    multi method charset($k) {
        self.protect: -> { %!charset{$k} }
    }
    multi method charset {
        %!charset
    }
    method use-cid($cid) {
        with @!spare-cids.first({$_ == $cid}, :k) {
            @!spare-cids[$_] = 0;
        }
        @!spare-cids.shift
            while @!spare-cids && @!spare-cids.head == 0;
    }

    method set-encoding($ord, $cid) {
        unless %!from-unicode{$ord} ~~ $cid {
            %!from-unicode{$ord} = $cid;
            @!to-unicode[$cid] = $ord;
            %!charset{$ord} = $cid;
            $.add-glyph-diff($cid);
        }
        $cid;
    }
    method add-encoding($ord) {
        my $cid = %!from-unicode{$ord} // 0;

        if $cid {
            %!charset{$ord} = $cid;
        }
        else {
            my $glyph-name = self.lookup-glyph($ord);
            if $glyph-name && $glyph-name ne '.notdef' {
                # try to remap the glyph to a spare encoding or other unused glyph
                while @!spare-cids && !$cid {
                    $cid = @!spare-cids.shift;
                    my $old-ord = @!to-unicode[$cid];
                    if $old-ord && %!charset{$old-ord} {
                        # already inuse
                        $cid = 0;
                    }
                    else {
                        # add it to the encoding scheme
                        self.set-encoding($ord, $cid);
                    }
                }
            }
        }
        $cid;
    }

    # transcoding interface (encode/decode) has:
    # - two stage encoding, :cids, --> Str
    # - three stage decoding :cids, :ords, --> Str.
    #
    # This is because not all layers are present in all PDF's and not all
    # layers need to decoded. For example PDF::To::Cairo only needs to decode
    # to cids to render PDFs. ords mapping may or may not be present.

    multi method encode(Str $text, :cids($)! --> Seq) {
        $text.ords.map({self.protect: {%!charset{$_} || self.add-encoding($_) || Empty }});
    }

    multi method encode(Str $text --> Str) {
        self.encode-cids: self.encode($text, :cids);
    }

    method encode-cids(@cids is raw) {
        buf8.new(@cids).decode: 'latin-1';
    }

    multi method decode(Str $encoded, :cids($)!) {
        $encoded.ords;
    }
    multi method decode(Str $encoded, :ords($)!) {
        self.protect: { $encoded.ords.map: {@!to-unicode[$_] || Empty} };
    }
    multi method decode(Str $encoded --> Str) {
        self.decode($encoded, :ords)».chr.join;
    }

}
