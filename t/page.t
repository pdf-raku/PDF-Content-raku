use v6;
use Test;
plan 7;

use lib 't';
use PDF::Content::Page :PageSizes;
use PDFTiny;
# ensure consistant document ID generation
srand(123456);

my PDFTiny $doc .= new;
my $page = $doc.page;
does-ok $page, PDF::Content::Page;
$page.media-box = PageSizes::Letter;
$page.bleed = 3;
is $page.media-box, [0,0,612,792];
is $page.bleed-box, [-3, -3, 612+3, 792+3];

$page.media-box = 'A4';
is $page.media-box, [0,0, 595, 842];
$page.bleed = 5;
is $page.bleed-box, [-5, -5, 595+5, 842+5];

dies-ok {$page.media-box = 'Blah'};
is $page.media-box, [0,0, 595, 842];

done-testing;
