use v6;
use Test;
use PDF::Basic::Image;

throws-like { PDF::Basic::Image.open( "t/images.t" ) }, ::('X::PDF::Image::UnknownType'), 'file extension check';

require ::('PDF::Basic::Image::PNG');
throws-like { ::('PDF::Basic::Image::PNG').read( "t/images/lightbulb.gif".IO.open ) }, ::('X::PDF::Image::WrongHeader'), 'PNG header-check';

require ::('PDF::Basic::Image::JPEG');
throws-like { ::('PDF::Basic::Image::JPEG').read( "t/images/lightbulb.gif".IO.open ) }, ::('X::PDF::Image::WrongHeader'), 'JPEG header-check';

require ::('PDF::Basic::Image::GIF');
throws-like { ::('PDF::Basic::Image::GIF').read( "t/images/basn0g01.png".IO.open ) }, ::('X::PDF::Image::WrongHeader'), 'GIF header-check';

done-testing;
