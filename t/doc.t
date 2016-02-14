use v6;
use Test;

use PDF::Graphics::Doc;
my $doc = PDF::Graphics::Doc.new;
my $page = $doc.add-page;
my $gfx = $page.gfx;
my $img = $gfx.load-image: "t/images/basn0g01.png";
$gfx.do($img, 100, 100);
lives-ok { $doc.save-as("t/doc.pdf") }, 'save-as';

done-testing;
