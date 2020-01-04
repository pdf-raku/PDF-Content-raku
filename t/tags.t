use v6;
use Test;
plan 2;

use lib 't/lib';
use PDFTiny;
use PDF::Content::Tag;

# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;

my PDFTiny::Page $page = $pdf.add-page;
my $gfx = $page.gfx;

my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );
my $body-font = $page.core-font( :family<Helvetica> );

$gfx.tag: 'H1', {
    .text: {
        .text-position = 50, 100;
        .font = $header-font, 14;
        .say('Header text');
    }
};

$gfx.tag: 'P', {
    .text: {
        .text-position = 70, 100;
        .font = $body-font, 12;
        .say('Some body text');
    }
};

my $kids = $gfx.tags;

# finishing work; normally undertaken by the API

my $doc = PDF::Content::Tag.new: :name<Document>, :$kids, :atts{ :test<yep> };

is $doc.descendant-tags.map(*.name).join(','), 'Document,H1,P';
my ($struct-tree, $Nums) = $doc.build-struct-tree;
$pdf.Root<StructTreeRoot> = $struct-tree;
($pdf.Root<MarkedInfo> //= {})<Marked> = True;
for @$Nums -> $n, $parent {
    $parent<StructParents> = $n;
}

lives-ok {$pdf.save-as: "t/tags.pdf";}

done-testing;
