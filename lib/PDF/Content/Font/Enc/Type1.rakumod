use PDF::Content::Font::Enc::Glyphic;

#| Implements a Type-1 single byte font encoding scheme.
#| it optimises the encoding to accomodate any subset of
#| <= 255 unique glyphs; by (1) using the standard
#| encoding for the glyph (2) mapping codes that are not
#| used in the encoding scheme, or (3) re-allocating codes
#| that have not been used.
class PDF::Content::Font::Enc::Type1
    does PDF::Content::Font::Enc::Glyphic {
    use PDF::Content::Font::Encodings :mac-encoding, :win-encoding, :sym-encoding, :std-encoding, :zapf-encoding, :zapf-glyphs, :mac-extra-encoding;
    has UInt %!from-unicode;  #| all encoding mappings
    has UInt %.charset{UInt}; #| used characters (useful for subsetting)
    has uint16 @.to-unicode[256];
    has uint8 @!spare-cids;   #| unmapped codes in the encoding scheme
    my subset EncodingScheme of Str where 'mac'|'win'|'sym'|'zapf'|'std'|'mac-extra';
    has EncodingScheme $.enc = 'win';

    submethod TWEAK {
        my array $encoding = %(
            :mac($mac-encoding),   :win($win-encoding),
            :sym($sym-encoding),   :std($std-encoding),
            :mac-extra($mac-extra-encoding),
            :zapf($zapf-encoding),
        ){$!enc};

	self.glyphs = $zapf-glyphs
            if $!enc eq 'zapf';

        @!to-unicode = $encoding.list;
        my uint16 @allocated-cids;
        for 1 .. 255 -> $cid {
            my uint16 $code-point = @!to-unicode[$cid];
            if $code-point {
                %!from-unicode{$code-point} = $cid;
                # CID used in this encoding schema. rellocate as a last resort
                @allocated-cids.unshift: $cid;
            }
            else {
                # spare CID use it first
                @!spare-cids.push($cid)
            }
        }
        # also keep track of codes that are allocated in the encoding scheme, but
        # have not been used in this encoding instance's charset. These can potentially
        # be added to differences to squeeze the most out of our 8-bit encoding scheme.
        @!spare-cids.append: @allocated-cids;
        # map non-breaking space to a regular space
        %!from-unicode{"\c[NO-BREAK SPACE]".ord} //= %!from-unicode{' '.ord};
    }

    method use-cid($cid) {
        with @!spare-cids.first({$_ == $cid}, :k) {
            @!spare-cids[$_] = 0;
        }
    }

    method set-encoding($chr-code, $cid) {
        unless %!from-unicode{$chr-code} ~~ $cid {
            %!from-unicode{$chr-code} = $cid;
            @!to-unicode[$cid] = $chr-code;
            %!charset{$chr-code} = $cid;
            $.add-glyph-diff($cid);
        }
    }
    method add-encoding($chr-code) {
        my $cid = %!from-unicode{$chr-code} // 0;

        if $cid {
            %!charset{$chr-code} = $cid;
        }
        else {
            my $glyph-name = self.lookup-glyph($chr-code) // '.notdef';
            unless $glyph-name eq '.notdef' {
                # try to remap the glyph to a spare encoding or other unused glyph
                while @!spare-cids && !$cid {
                    $cid = @!spare-cids.shift;
                    if $cid {
                        my $old-chr-code = @!to-unicode[$cid];
                        if $old-chr-code && %!charset{$old-chr-code} {
                            # already inuse
                            $cid = 0;
                        }
                        else {
                            # add it to the encoding scheme
                            self.set-encoding($chr-code, $cid);
                        }
                    }
                }
            }
        }
        $cid;
    }

    multi method encode(Str $text, :cids($)! --> buf8) is default {
        buf8.new: $text.ords.map({%!charset{$_} || self.add-encoding($_) }).grep: {$_};
    }

    multi method encode(Str $text --> Str) {
        self.encode($text, :cids).decode: 'latin-1';
    }

    multi method decode(Str $encoded, :cids($)!) {
        $encoded.ords;
    }
    multi method decode(Str $encoded, :ords($)!) {
        $encoded.ords.map({@!to-unicode[$_]}).grep: {$_};
    }
    multi method decode(Str $encoded --> Str) {
        self.decode($encoded, :ords)».chr.join;
    }

}
