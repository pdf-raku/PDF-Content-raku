use v6;
use Test;
use PDF::Graphics::Image;

throws-like { PDF::Graphics::Image.open( "t/images.t" ) }, ::('X::PDF::Image::UnknownType'), 'file extension check';

require ::('PDF::Graphics::Image::PNG');
throws-like { ::('PDF::Graphics::Image::PNG').read( "t/images/lightbulb.gif".IO.open ) }, ::('X::PDF::Image::WrongHeader'), 'PNG header-check';

require ::('PDF::Graphics::Image::JPEG');
throws-like { ::('PDF::Graphics::Image::JPEG').read( "t/images/lightbulb.gif".IO.open ) }, ::('X::PDF::Image::WrongHeader'), 'JPEG header-check';

require ::('PDF::Graphics::Image::GIF');
throws-like { ::('PDF::Graphics::Image::GIF').read( "t/images/basn0g01.png".IO.open ) }, ::('X::PDF::Image::WrongHeader'), 'GIF header-check';

done-testing;
