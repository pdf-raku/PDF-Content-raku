use v6;
use Test;
plan 9;

use lib 't';
use PDFTiny;
use PDF::Content::Tag :ParagraphTags, :IllustrationTags;
use PDF::Content::XObject;
use PDF::Content::FontObj;

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my PDF::Content::FontObj $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my PDF::Content::FontObj $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;

    my $*ActualText = '';
    $tag = $gfx.mark: Header1, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    is $tag.name, 'H1', 'mark tag name';
    is $tag.mcid, 0, 'mark tag mcid';
    is-deeply $*ActualText.lines, ('Header text',), '$*ActualText';

    $tag = $gfx.mark: Paragraph, {
        .say('Paragraph that contains a figure', :position[50, 100], :font($body-font), :font-size(12));

        .tag: Figure, {
            my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
            .do: $img, :position[50,70];
        }

    }

    is $tag.name, 'P', 'outer tag name';
    is $tag.kids[0].name, 'Figure', 'inner tag name';
    is-deeply $*ActualText.lines, ('Header text', 'Paragraph that contains a figure'), '$*ActualText';
}

is $page.gfx.tags.gist, '<H1 MCID="0"/><P MCID="1"><Figure/></P>';

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as: "t/tags.pdf" }

# check we can re-read tagged content

$pdf .= open: "t/tags.pdf";

is $pdf.page(1).render.tags.gist, '<H1 MCID="0"/><P MCID="1"><Figure/></P>';

done-testing;
