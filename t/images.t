use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;

use PDF::Graphics::Image;

my $jpeg;
lives-ok {$jpeg = PDF::Graphics::Image.open: "t/images/jpeg.jpg";}, "open jpeg - lives";
isa-ok $jpeg, ::('PDF::DAO::Stream'), 'jpeg object';
is $jpeg<Type>, 'XObject', 'jpeg type';
is $jpeg<Subtype>, 'Image', 'jpeg subtype';
is $jpeg<Width>, 24, 'jpeg width';
is $jpeg<Height>, 24, 'jpeg height';
is $jpeg<BitsPerComponent>, 8, 'jpeg bpc';
is $jpeg<ColorSpace>, 'DeviceRGB', 'jpeg cs';
ok $jpeg<Length>, 'jpeg dict length';
is $jpeg.encoded.codes, $jpeg<Length>, 'jpeg encoded length';

my $gif;
lives-ok {$gif = PDF::Graphics::Image.open: "t/images/lightbulb.gif";}, "open gif - lives";
isa-ok $gif, ::('PDF::DAO::Stream'), 'gif object';
is $gif<Type>, 'XObject', 'gif type';
is $gif<Subtype>, 'Image', 'gif subtype';
is $gif<Width>, 19, 'gif width';
is $gif<Height>, 19, 'gif height';
is $gif<BitsPerComponent>, 8, 'gif bpc';
is-json-equiv $gif<ColorSpace>, ['Indexed', 'DeviceRGB', 31, "\xFF\xFF\xFF\xFF\xFB\xF0\xFF\xDF\xFF\xD4\xDF\xFF\xCC\xCC\xFF\xC0\xDC\xC0\xA6\xCA\xF0\xFF\x98\xFF\xFF\xFF\xAA\xFF\xDF\xAA\xD4\xDF\xAA\xD4\xBF\xAA\xD4\x9F\xAA\xAA\xBF\xAA\xA0\xA0\xA4\xAA\x9F\xAA\x80\x80\x80\x7F\x9F\xAA\xFF\xFF\x55\xFF\xDF\x55\xD4\xBF\x55\xD4\x9F\x55\xAA\x9F\x55\x80\x80\x00\xAA\x7F\x55\xAA\x5F\x55\xAA\x7F\x00\x7F\x5F\x55\x55\x5F\x55\x2A\x5F\x55\x55\x3F\x55\x00\x00\x00" ], 'gif cs';
ok $gif<Length>, 'gif dict length';
is $gif.encoded.codes, $gif<Length>, 'gif encoded length';

done-testing;
