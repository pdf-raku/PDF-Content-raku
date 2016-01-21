use v6;

role PDF::Graphics::Image {

    use PDF::DAO;

    #| lightweight replacement for deprecated $buf.unpack
    sub unpack(buf8 $buf, *@templ) {
	my @bytes = $buf.list;
	my $i = 0;
	my UInt @out;
	for @templ -> $unit {
	    my UInt $size = $unit.^nativesize div 8;
	    my UInt $v = 0;
	    for 1 .. $size {
                # network byte order
		$v +<= 8; $v += @bytes[$i++];
	    }
	    @out.append: $v
	}
	@out;
    }

    method open($spec! where Str | IO::Handle ) {
        self.read($spec);
    }

    multi method read(Str $path! ) {
        self.read( $path.IO.open( :r, :enc<latin-1> ) );
    }

    multi method read(IO::Handle $fh! where $fh.path.extension ~~ m:i/ jpe?g $/) {
        my Blob $buf;
        my Int ($bpc, $height, $width, $cs);
        my Bool $is-dct;

        $fh.seek(0, SeekFromBeginning);
        $buf = $fh.read(2);
        my @soi = unpack($buf, uint8, uint8);
        die "image doesn't have a JPEG header"
            unless @soi[0] == 0xFF and @soi[1] == 0xD8;

        loop {
            $buf = $fh.read: 4;
            my UInt ($ff, $mark, $len) = unpack($buf, uint8, uint8, uint16);
            last if $ff != 0xFF;
            last if $mark == 0xDA | 0xD9;  # SOS/EOI
            last if $len < 2;
            last if $fh.eof;

            $buf = $fh.read($len-2);
            next if $mark == 0xFE;
            next if 0xE0 <= $mark <= 0xEF;
            if 0xC0 <= $mark <= 0xCF
            && $mark != 0xC4 | 0xC8 | 0xCC {
                $is-dct = ?( $mark == 0xC0 | 0xC2);
                ($bpc, $height, $width, $cs) = unpack($buf, uint8, uint16, uint16, uint8);
                last;
            }
        }

        my Str $color-space = do given $cs {
            when 3 {'DeviceRGB'}
            when 4 {'DeviceCMYK'}
            when 1 {'DeviceGray'}
            default {warn "JPEG has unknown color-space: $_";
                     'DeviceGray'}
        }

        my $dict = { :Type( :name<XObject> ), :Subtype( :name<Image> ) };
        $dict<Width> = $width;
        $dict<Height> = $height;
        $dict<BitsPerComponent> = $bpc;
        $dict<ColorSpace> = :name($color-space);
        $dict<Filter> = :name<DCTDecode>
            if $is-dct;

        $fh.seek(0, SeekFromBeginning);
        my $encoded = $fh.slurp-rest;
        $fh.close;

        PDF::DAO.coerce( :$dict, :$encoded );
    }

    multi method read(IO::Handle $fh!) is default {
        my Str $ext = $fh.path.extension;
        die ($ext
             ?? "can't yet handle files of type: $ext"
             !! "unable to determine image-type: {$fh.path.basename}");
    }


}
