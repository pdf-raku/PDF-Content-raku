use v6;
use PDF::Graphics::Image;
use PDF::DAO;

# adapted from Perl 5's PDF::API::Resource::XObject::Image::GIF

class PDF::Graphics::Image::GIF
    is PDF::Graphics::Image {

    method network-endian { False }

    method !read-colorspace(IO::Handle $fh,  UInt $flags, %dict) {
        my UInt $col-size = 2 ** (($flags +& 0x7) + 1);
        my Str $encoded = $fh.read( 3 * $col-size).decode('latin-1');
        my $color-table = $col-size > 64
            ?? PDF::DAO.coerce( :stream{ :$encoded } )
            !! :hex-string($encoded);
        %dict<ColorSpace> = [ :name<Indexed>, :name<DeviceRGB>, :int($col-size-1), $color-table ];
    }

    sub vec(buf8 $buf, UInt $off) {
        ($buf[ $off div 8] +> ($off % 8)) % 2
    }

    method !de-compress(UInt $ibits, buf8 $stream) {
        my UInt $bits = $ibits;
        my UInt $reset-code = 1 +< ($ibits-1);
        my UInt $end-code   = $reset-code + 1;
        my UInt $next-code  = $end-code+1;
        my UInt $ptr = 0;
        my UInt $maxptr = 8 * +$stream;
        my UInt $tag;
        my Str $out = '';
        my UInt $outptr = 0;

        my Str @d = (0 ..^ $reset-code).map: *.chr;

        while ($ptr + $bits) <= $maxptr {
            $tag = 0;
            for (reverse 0 ..^ $bits) -> $off {
                $tag +<= 1;
                $tag +|= vec($stream, $ptr + $off);
            }
            $ptr += $bits;
            $bits++
                if $next-code == 1 +< $bits and $bits < 12;

            if $tag == $reset-code {
                $bits = $ibits;
                $next-code = $end-code + 1;
                next;
            } elsif $tag == $end-code {
                last;
            } elsif $tag < $reset-code {
                @d[$next-code] = @d[$tag];
                $out ~= @d[$next-code];
                $next-code++;
            } elsif $tag > $end-code {
                @d[$next-code] = @d[$tag];
                @d[$next-code] ~= substr(@d[$tag + 1], 0, 1);
                $out ~= @d[$next-code];
                $next-code++;
            }
        }

        $out;
    }

    method !de-interlace(Str $data, UInt $width, UInt $height) {
        my UInt $row;
        my Str @result;
        my UInt $idx = 0;

        #Pass 1 - every 8th row, starting with row 0
        $row = 0;
        while $row < $height {
            @result[$row] = substr($data, $idx*$width, $width);
            $row += 8;
            $idx++;
        }

        #Pass 2 - every 8th row, starting with row 4
        $row = 4;
        while $row < $height {
            @result[$row] = substr($data, $idx*$width, $width);
            $row += 8;
            $idx++;
        }

        #Pass 3 - every 4th row, starting with row 2
        $row = 2;
        while $row < $height {
            @result[$row] = substr($data, $idx*$width, $width);
            $row += 4;
            $idx++;
        }

        #Pass 4 - every 2th row, starting with row 1
        $row = 1;
        while $row < $height {
            @result[$row] = substr($data, $idx*$width, $width);
            $row += 2;
            $idx++;
        }

        [~] @result
    }

    method read(IO::Handle $fh!, Bool :$trans = True) {

        my %dict = :Type( :name<XObject> ), :Subtype( :name<Image> );
        my Bool $interlaced = False;
        my Str $decoded = '';

        my $buf = $fh.read: 6; # signature
        die "{$fh.path} unknown image signature {$buf.decode('latin-1').perl} -- not a gif."
            unless $buf.decode('latin-1') ~~ /^GIF <[0..9]>**2 [a|b]/;

        $buf = $fh.read: 7; # logical descr.
        my ($wg, $hg, $flags, $bgColorIndex, $aspect) = $.unpack($buf, uint16, uint16, uint8, uint8, uint8);

        self!read-colorspace($fh, $flags, %dict)
            if $flags +& 0x80;

        while !$fh.eof {
            my ($sep) = $.unpack( $fh.read(1), uint8); # tag.

            given $sep {
                when 0x2C {
                    $buf = $fh.read(9); # image-descr.
                    my ($left,$top,$w,$h,$flags) = $.unpack($buf, uint16, uint16, uint16, uint16, uint8);

                    %dict<Width>  = $w || $wg;
                    %dict<Height> = $h || $hg;
                    %dict<BitsPerComponent> = 8;

                    self!read-colorspace($fh, $flags, %dict)
                        if $flags +& 0x80; # local colormap

                    $interlaced = True  # need de-interlace
                        if $flags &+ 0x40;

                    my ($sep, $len) = $.unpack( $fh.read(2), uint8, uint8); # image-lzw-start (should be 9) + length.
                    my $stream = buf8.new;

                    while $len {
                        $stream.append: $fh.read($len).list;
                        ($len,) = $.unpack($fh.read(1), uint8);
                    }

                    $decoded = self!de-compress($sep+1, $stream);
                    $decoded = self!de-interlace($decoded, %dict<Width>, %dict<Height> )
                        if $interlaced;
                    last;
                }

                when 0x3b {
                    last;
                }

                when 0x21 {
                    # Graphic Control Extension
                    my ($tag, $len) = $.unpack( $fh.read(2), uint8, uint8);
                    die "unsupported graphic control extension ($tag)"
                        unless $tag == 0xF9;

                    my $stream = Buf.new;

                    while $len {
                        $stream.append: $fh.read($len).list;
                        ($len,) = $.unpack($fh.read(1), uint8);
                    }

                    my ($cFlags,$delay,$transIndex) = $.unpack($stream, uint8, uint16, uint8);
                    if ($cFlags +& 0x01) && $trans {
                        %dict<Mask> = [$transIndex, $transIndex];
                    }
                }
                default {
                    # misc extension
                    my ($tag, $len) = $.unpack( $fh.read(1), uint8, uint8);

                    # flush it
                    while $len {
                        $fh.read: $len;
                        ($len,) = $.unpack($fh.read(1), uint8);
                    }
                }
            }
        }
        $fh.close;

        PDF::DAO.coerce( :%dict, :$decoded );
    }

}
