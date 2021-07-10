role PDF::Content::Font::Enc::Glyphic {
    use Font::AFM;
    has Hash $.glyphs is rw = %Font::AFM::Glyphs;
    use PDF::COS;
    use PDF::COS::Name;
    my subset NameOrUInt where PDF::COS::Name|UInt;
    has PDF::COS::Name %!diffs{UInt};

    method lookup-glyph(UInt $ord) {
        $!glyphs{$ord.chr}
    }

    method glyph-map {
        %( $!glyphs.invert );
    }

    method add-glyph-diff(UInt $cid) {
        if @.to-unicode[$cid] -> $ord {
            my $glyph-name = self.lookup-glyph( $ord ) // '.notdef';
            %!diffs{$cid} = PDF::COS::Name.COERCE: $glyph-name
                unless $glyph-name eq '.notdef';
        }
    }

    method cid-map-glyph($glyph-name, $cid) {
        # default handling
        warn "ignoring glyph /$glyph-name ($cid)";
    }

    method differences is rw {
        Proxy.new(
            STORE => -> $, @diffs {
                my %glyph-map := self.glyph-map;
                my uint32 $cid = 0;

                for @diffs {
                    when UInt { $cid  = $_ }
                    when Str {
                        my $name = $_;
                        with %glyph-map{$name} {
                           self.set-encoding(.ord, $cid);
                        }
                        else {
                            self.use-cid($cid);
                            self.cid-map-glyph($name, $cid);
                        }
                        %!diffs{$cid++} = PDF::COS::Name.COERCE($_);
                    }
                    default { die "bad difference entry: .raku" }
                }
            },
            FETCH => {
                my $cid := -2;
                my @diffs;
                %!diffs.pairs.sort.map: {
                    unless .value eq '.notdef' {
                        push @diffs: .key
                            unless .key == $cid + 1;
                        push @diffs: .value;
                        $cid := .key;
                    }
                }
                @diffs;
            },
        )
    }
}
