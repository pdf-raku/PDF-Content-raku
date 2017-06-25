use v6;
use Test;
use PDF::Content::Image::PNG;

my $png = PDF::Content::Image::PNG.new.read: "t/images/basn0g08.png".IO.open(:r);

is $png.hdr.width, 32, 'width';
is $png.hdr.height, 32, 'height';
is $png.hdr.bit-depth, 8, 'bit-depth';
is $png.hdr.color-type, 0, 'color-type';
is $png.hdr.compression-type, 0, 'compression-type';
is $png.hdr.interlace-type, 0, 'interlace-type';

note $png.Buf.decode('latin-1').perl;

done-testing;
