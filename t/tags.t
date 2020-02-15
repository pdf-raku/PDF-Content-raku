use v6;
use Test;
plan 6;

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

    $gfx.tag.Paragraph: {
        .text: {
            .say('Some body text', :tag<Span>, :position[50, 100], :font($body-font), :font-size(12));
            $tag = $gfx.closed-tag;
        }
    }
    is $tag.name, 'Span', 'inner tag name';
    is $gfx.closed-tag.name, 'P', 'outer tag name';

    sub outer-rect(*@rects) {
        [
            @rects.map(*[0].round).min, @rects.map(*[1].round).min,
            @rects.map(*[2].round).max, @rects.map(*[3].round).max,
        ]
    }

    my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
    $gfx.set-tag-bbox: $gfx.tag.Figure: {
        outer-rect([
            $gfx.do($img, :position[50, 70]),
            $gfx.say("Eureka!", :tag<Caption>, :position[40, 60]),
        ]);
    }
    $tag = $gfx.closed-tag;
    is-deeply $tag.attributes<BBox>, [40, 60, 81, 89], 'image tag BBox';
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
