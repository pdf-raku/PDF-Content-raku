use v6;
use Test;
plan 9;

use lib 't';
use PDFTiny;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags, :StructureTags;
use PDF::Content::Tag::Elem;
use PDF::Content::Tag::Mark;
use PDF::Content::Tag::Root;
use PDF::Content::XObject;

# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

my PDF::Content::Tag::Root $tags .= new;
my PDF::Content::Tag::Elem $doc = $tags.add-kid(Document);

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;
    my PDF::Content::Tag $tag2;

    $tag = $doc.add-kid(Header1).mark: $gfx, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    is $tag.name, 'H1', 'mark tag name';
    is $tag.mcid, 0, 'mark tag mcid';
    is $tag.parent.name, 'H1', 'parent elem name';

    $tag = $doc.add-kid(Paragraph).mark: $gfx, {
        .say('Some body text', :position[50, 100], :font($body-font), :font-size(12));
    }
    is $tag.name, 'P', 'inner tag name';
    is $tag.parent.name, 'P', 'outer tag name';

    sub outer-rect(*@rects) {
        [
            @rects.map(*[0].round).min, @rects.map(*[1].round).min,
            @rects.map(*[2].round).max, @rects.map(*[3].round).max,
        ]
    }

    my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";

    my @rect;
    $tag = $doc.add-kid(Figure).mark: $gfx, {
        @rect = outer-rect([
            $gfx.do($img, :position[50, 70]),
            $gfx.say("Eureka!", :tag<Caption>, :position[40, 60]),
            ]);
    }
    $tag.parent.set-bbox($gfx, @rect);
    is-deeply $tag.parent.attributes<BBox>, [40, 60, 81, 89], 'image tag BBox';

    my Hash $link = PDF::COS.coerce: :dict{
        :Type(:name<Annot>),
        :Subtype(:name<Link>),
        :Rect[71, 717, 190, 734],
        :Border[16, 16, 1, [3, 2]],
        :Dest[ $page, :name<FitR>, -4, 399, 199, 533 ],
        :P($page),
    };

    $doc.add-kid(Link).reference($gfx, $link);

    my  PDF::Content::XObject $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        .mark: Header1, { .say: "Tagged XObject header", :font($header-font), :$font-size};
        .mark: Paragraph, { .say: "Some sample tagged text", :font($body-font), :$font-size};
    }

    $doc.add-kid(Form).do: $gfx, $form, :marks, :position[150, 70];
}

is $doc.descendants.map(*.name).join(','), 'Document,H1,P,Figure,Link,Form';
$pdf.Root<StructTreeRoot> = $tags.build-struct-tree;
.<Marked> = True
    given $pdf.Root<MarkInfo> //= {};

lives-ok { $pdf.save-as: "t/tags.pdf" }

# check we can re-read tagged content

$pdf .= open: "t/tags.pdf";

is $pdf.page(1).render.tags.gist, '<H1 MCID="0"/><P MCID="1"/><Figure MCID="2"/>';

done-testing;
