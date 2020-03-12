use v6;
use Test;
plan 6;

use lib 't';
use PDFTiny;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags, :StructureTags;
use PDF::Content::XObject;

# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;

    $tag = $gfx.mark: Header1, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    is $tag.name, 'H1', 'mark tag name';
    is $tag.mcid, 0, 'mark tag mcid';

    $tag = $gfx.mark: Paragraph, {
        .say('Some body text', :position[50, 100], :font($body-font), :font-size(12));
    }
    is $tag.name, 'P', 'inner tag name';

    sub outer-rect(*@rects) {
        [
            @rects.map(*[0].round).min, @rects.map(*[1].round).min,
            @rects.map(*[2].round).max, @rects.map(*[3].round).max,
        ]
    }

    my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";

    my  PDF::Content::XObject $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    $gfx.tag: Figure, {
        $form.text: {
            my $font-size = 12;
            .text-position = [10, 38];
            .mark: Header1, { .say: "Tagged XObject header", :font($header-font), :$font-size};
            .mark: Paragraph, { .say: "Some sample tagged text", :font($body-font), :$font-size};
        }
    }

}

is $page.gfx.tags.gist, '<H1 MCID="0"/><P MCID="1"/><Figure/>';

lives-ok { $pdf.save-as: "t/tags.pdf" }

# check we can re-read tagged content

$pdf .= open: "t/tags.pdf";

is $pdf.page(1).render.tags.gist, '<H1 MCID="0"/><P MCID="1"/><Figure/>';

done-testing;
