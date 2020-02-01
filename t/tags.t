use v6;
use Test;
plan 2;

use lib 't/lib';
use PDFTiny;
use PDF::Content::Tag::Elem;
use PDF::Content::Tag::Marked;
use PDF::Content::XObject;

# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );
my $body-font = $page.core-font( :family<Helvetica> );

my PDF::Content::Tag::Elem $doc .= new: :name<Document>, :attributes{ :test<yep> };

$doc.graphics: $page, -> $gfx {

    my @rect;
    my PDF::Content::Tag::Marked $tag;
    $tag = $gfx.tag: 'H1', {
        .text: {
            .text-position = 50, 120;
            .font = $header-font, 14;
            @rect = .say('Header text');
        }
    };
    $tag.attributes<BBox> = [ $gfx.base-coords(@rect) ];

    $tag = $gfx.tag.Paragraph: {
        .text: {
            .text-position = 50, 100;
            .font = $body-font, 12;
            @rect = .say('Some body text');
        }
    }
    $tag.attributes<BBox> = [ $gfx.base-coords(@rect) ];

    $tag = $gfx.tag.Figure: {
        my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
       @rect = .do: $img, 50, 70;
    }
    $tag.attributes<BBox> = [ $gfx.base-coords(@rect) ];
};

# finishing work; normally undertaken by the API

is $doc.descendant-tags.map(*.name).join(','), 'Document,H1,P,Figure';
my ($struct-tree, $Nums) = $doc.build-struct-tree;
$pdf.Root<StructTreeRoot> = $struct-tree;
($pdf.Root<MarkedInfo> //= {})<Marked> = True;
for @$Nums -> $n, $parent {
    $parent<StructParents> = $n;
}

lives-ok {$pdf.save-as: "t/tags.pdf";}

done-testing;
