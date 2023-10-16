#| base role for non-cid glyph name lookup
unit role PDF::Content::Font::Enc::Glyphic;

    use Font::AFM;
has Hash $.glyphs = %Font::AFM::Glyphs;
use PDF::COS;
use PDF::COS::Name;
my subset NameOrUInt where PDF::COS::Name|UInt;
has PDF::COS::Name %.diffs{UInt}; # custom or standard glyph name

#| Get the standard glyph name for a character
method lookup-glyph(UInt $ord --> Str) {
    $!glyphs{$ord.chr} // Str;
}

#| Get the locally definition for a glyph
method local-glyph-name(UInt $cid --> Str) {
    %!diffs{$cid} // Str;
}

#| return a mapping of glyph names to CIDS
method glyph-map returns Hash {
    %( $!glyphs.invert );
}

#| register this glyph in the differences table
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

#| set or get the Type1 differences table
method differences is rw {
    Proxy.new(
        STORE => -> $, @diffs {
            my %glyph-map := self.glyph-map;
            my uint32 $cid = 0;

            multi sub add-diff(UInt:D $_) { $cid = $_}
            multi sub add-diff(Str:D $name) {
                with %glyph-map{$name} {
                    self.set-encoding(.ord, $cid);
                }
                else {
                    self.use-cid($cid);
                    self.cid-map-glyph($name, $cid);
                }
                %!diffs{$cid++} = PDF::COS::Name.COERCE($name);
            }
            multi sub add-diff($_) is hidden-from-backtrace {
                die "bad difference entry: .raku";
            }

            add-diff($_) for @diffs;
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
