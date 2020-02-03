use v6;
use Test;
plan 7;

use lib 't/lib';
use PDFTiny;
use PDF::Content::Tag :ParagraphTags;
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
    my PDF::Content::Tag::Marked $tag2;
    $gfx.text: {
        .say('Header text',
             :tag(Header1),
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }
    $tag = $gfx.closed-tag;
    is $tag.name, 'H1', 'tag name';
    is-deeply [ $tag.attributes<BBox>.map(*.round) ], [50, 120, 132, 137], 'tag BBox';

    $tag2 = $gfx.tag.Paragraph: {
        .text: {
            @rect = .say('Some body text', :tag<Span>, :position[50, 100], :font($body-font), :font-size(12));
            $tag = $gfx.closed-tag;
        }
    }
    is $tag.name, 'Span', 'inner tag name';
    is $tag2.name, 'P', 'outer tag name';

    my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
    @rect = $gfx.do: $img, 50, 70, :tag<Figure>;
    $tag = $gfx.closed-tag;
    is-deeply $tag.attributes<BBox>, [50, 70, 69, 89], 'image tag BBox';
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
