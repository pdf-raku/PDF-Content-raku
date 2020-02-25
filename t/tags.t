use v6;
use Test;
plan 6;

use lib 't';
use PDFTiny;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags;
use PDF::Content::Tag::Elem;
use PDF::Content::Tag::Mark;
use PDF::Content::XObject;

# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );
my $body-font = $page.core-font( :family<Helvetica> );

my PDF::Content::Tag::Elem $doc .= new: :name<Document>, :attributes{ :test<yep> };

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;
    my PDF::Content::Tag $tag2;
    $doc.add-kid(Header1).graphics: $gfx, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }
    $tag = $gfx.closed-tag.parent;
    is $tag.name, 'H1', 'tag name';

    $doc.add-kid(Paragraph).graphics: $gfx, {
        .say('Some body text', :position[50, 100], :font($body-font), :font-size(12));
        $tag = $gfx.closed-tag;
    }
    is $tag.name, 'Span', 'inner tag name';
    is $tag.parent.name, 'P', 'outer tag name';

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
    my $figure = $gfx.closed-tag;
    is-deeply $figure.attributes<BBox>, [40, 60, 107, 89], 'image tag BBox';
    $doc.add-kid($figure);

    my Hash $link = PDF::COS.coerce: :dict{
        :Type(:name<Annot>),
        :Subtype(:name<Link>),
        :Rect[71, 717, 190, 734],
        :Border[16, 16, 1, [3, 2]],
        :Dest[ { :Type(:name<Page>) }, :name<FitR>, -4, 399, 199, 533 ],
    };

    $doc.add-kid(Link).add-kid($link);
}

# finishing work; normally undertaken by the API
is $doc.descendant-tags.map(*.name).join(','), 'Document,H1,P,Figure,Link';
my ($struct-tree, $Nums) = $doc.build-struct-tree;
$pdf.Root<StructTreeRoot> = $struct-tree;
($pdf.Root<MarkedInfo> //= {})<Marked> = True;
for @$Nums -> $n, $parent {
    $parent<StructParents> = $n;
}

lives-ok {$pdf.save-as: "t/tags.pdf";}

done-testing;
