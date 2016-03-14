use v6;
use PDF::Basic::Image;
use PDF::DAO;

# adapted from Perl 5's PDF::API::Resource::XObject::Image::JPEG

class PDF::Basic::Image::JPEG
    is PDF::Basic::Image {

    method read(IO::Handle $fh!) {
        my Blob $buf;
        my Int ($bpc, $height, $width, $cs);
        my Bool $is-dct;

        $fh.seek(0, SeekFromBeginning);
        my $header = $fh.read(2).decode: 'latin-1';
        die X::PDF::Image::WrongHeader.new( :type<JPEG>, :$header, :$fh )
            unless $header ~~ "\xFF\xD8";

        loop {
            $buf = $fh.read: 4;
            my UInt ($ff, $mark, $len) = $.unpack($buf, uint8, uint8, uint16);
            last if $ff != 0xFF;
            last if $mark == 0xDA | 0xD9;  # SOS/EOI
            last if $len < 2;
            last if $fh.eof;

            $buf = $fh.read: $len - 2;
            next if $mark == 0xFE;
            next if 0xE0 <= $mark <= 0xEF;
            if 0xC0 <= $mark <= 0xCF
            && $mark != 0xC4 | 0xC8 | 0xCC {
                $is-dct = ?( $mark == 0xC0 | 0xC2);
                ($bpc, $height, $width, $cs) = $.unpack($buf, uint8, uint16, uint16, uint8);
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

        my %dict = :Type( :name<XObject> ), :Subtype( :name<Image> );
        %dict<Width> = $width;
        %dict<Height> = $height;
        %dict<BitsPerComponent> = $bpc;
        %dict<ColorSpace> = :name($color-space);
        %dict<Filter> = :name<DCTDecode>
            if $is-dct;

        $fh.seek(0, SeekFromBeginning);
        my $encoded = $fh.slurp-rest;
        $fh.close;

        PDF::DAO.coerce: :stream{ :%dict, :$encoded };
    }
}
