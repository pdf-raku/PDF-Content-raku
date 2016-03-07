use v6;

class X::PDF::Image::WrongHeader is Exception {
    has Str $.type is required;
    has Str $.header is required;
    has IO::Handle $.fh is required;
    method message {
        "{$!fh.path} image doesn't have a {$!type} header: {$.header.perl}"
    }
}

class X::PDF::Image::UnknownType is Exception {
    has IO::Path $.path;
    method message {
        for $!path.extension {
            $_
                ?? "can't yet handle files of type: $_"
                !! "unable to determine image-type: {$!path.basename}"
        }
    }
}

role PDF::Content::Image {

    use PDF::DAO;
    method network-endian { True }

    #| lightweight replacement for deprecated $buf.unpack
    method unpack(Buf $buf, *@templ ) {
	my @bytes = $buf.list;
        my Bool $nw = $.network-endian;
        my UInt $off = 0;

	@templ.map: {
	    my UInt $size = .^nativesize div 8;
	    my UInt $v = 0;
            my UInt $i = $nw ?? 0 !! $size;
            for 1 .. $size {
                $v +<= 8;
                $v += @bytes[$off + ($nw ?? $i++ !! --$i)];
	    }
            $off += $size;

	    $v;
	}
    }

    multi method open(Str $path! ) {
        self.open( $path.IO );
    }

    multi method open(IO::Path $io-path) {
        self.open( $io-path.open( :r, :enc<latin-1>) );
    }

    multi method open(IO::Handle $fh!) {
        my $path = $fh.path;
        my Str $type = do given $path.extension {
            when m:i/^ jpe?g $/ { 'JPEG' }
            when m:i/^ gif $/   { 'GIF' }
            when m:i/^ png $/   { 'PNG' }
            default {
                die X::PDF::Image::UnknownType.new( :$path );
            }
        };

        require ::('PDF::Content::Image')::($type);
        ::('PDF::Content::Image')::($type).read($fh);
    }

    method inline-to-xobject(Hash $inline-dict, Bool :$invert) {

        my constant %Abbreviations = %(
            # [PDF 1.7 TABLE 4.43 Entries in an inline image object]
            :BPC<BitsPerComponent>,
            :CS<ColorSpace>,
            :D<Decode>,
            :DP<DecodeParms>,
            :F<Filter>,
            :H<Height>,
            :IM<ImageMask>,
            :I<Interpolate>,
            :W<Width>,
            # [PDF 1.7 TABLE 4.44 Additional abbreviations in an inline image object]
            :G<DeviceGray>,
            :RGB<DeviceRGB>,
            :CMYK<DeviceCMYK>,
            # Notes:
            # 1. Ambiguous 'Indexed' entry seems to be a typo in the spec
            # 2. filter abbreviations are handled in PDF::Storage::Filter
            );

        my $alias = $invert ?? %Abbreviations.invert.Hash !! %Abbreviations;

        my %xobject-dict = $inline-dict.pairs.map: {
            ($alias{.key} // .key) => .value
        }

        %xobject-dict;
    }

}
