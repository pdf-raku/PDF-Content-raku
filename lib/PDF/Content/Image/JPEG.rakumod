
# adapted from Perl's PDF::API2::Resource::XObject::Image::JPEG
unit class PDF::Content::Image::JPEG;

use PDF::Content::Image;
also is PDF::Content::Image;

use X::PDF::Content;

use Native::Packing :Endian;
class Atts is repr('CStruct') does Native::Packing[Network] {
    has uint8 $.bit-depth;
    has uint16 ($.height, $.width);
    has uint8 $.color-channels
}
class BlockHeader is repr('CStruct') does Native::Packing[Network] {
    has uint8 ($.ff, $.mark);
    has uint16 $.len
}
# work-around for Rakudo RT #131122 - sign handling
# (fixed in Rakudo 2022.03+)
has Atts $!atts;
has Bool $!is-dct;
has Str $!encoded;

# work-around for Rakudo RT #131122 - sign handling
sub u8(uint8 $v) { $v }
sub u16(uint16 $v) { $v }

method read($fh = $.source) {
    $fh.seek(0, SeekFromBeginning);
    my Str $header = $fh.read(2).decode: 'latin-1';
    die X::PDF::Content::Image::WrongHeader.new( :type<JPEG>, :$header, :path($fh.path) )
        unless $header ~~ "\xFF\xD8";

    loop {
        my BlockHeader $hdr .= read: $fh;
        last if u8($hdr.ff) != 0xFF;
        last if u8($hdr.mark) ~~ 0xDA|0xD9;  # SOS/EOI
        my $len := u16($hdr.len);
        last if $len < 2;
        last if $fh.eof;

        my $buf := $fh.read: $len - 2;
        given $hdr.mark -> uint8 $mark {
            if 0xC0 <= $mark <= 0xCF
            && $mark !~~ 0xC4|0xC8|0xCC {
                $!is-dct = ?( $mark ~~ 0xC0|0xC2);
                $!atts .= unpack($buf);
                last;
            }
        }
    }

    $fh.seek(0, SeekFromBeginning);
    $!encoded = $fh.slurp(:bin).decode: "latin-1";
    $fh.close;
    self;
}

method to-dict {
    my %dict = :Type( :name<XObject> ), :Subtype( :name<Image> );
    with $!atts {
        my Str \color-space = do given .color-channels {
            constant @ColorSpaces = [Mu, 'DeviceGray', Mu, 'DeviceRGB', 'DeviceCMYK'];
            @ColorSpaces[$_]
            // do  {
                warn "JPEG has unknown color-channel: $_";
                'DeviceGray'
            }
        }

        %dict<ColorSpace> = :name(color-space);
        %dict<Width> = .width;
        %dict<Height> = .height;
        %dict<BitsPerComponent> = .bit-depth;
    }
    else {
        die "unable to read JPEG attributes";
    }
    %dict<Filter> = :name<DCTDecode>
        if $!is-dct;

    need PDF::COS::Stream;
    PDF::COS::Stream.COERCE: { :%dict, :$!encoded };
}

