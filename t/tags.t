use v6;
use Test;
plan 11;

use lib 't';
use PDFTiny;
use PDF::Content::Tag :Tags;
use PDF::Content::FontObj;
use PDF::Content::Page;
use PDF::Content::XObject;

my PDFTiny $pdf .= new;

my PDF::Content::Page $page = $pdf.add-page;
my PDF::Content::FontObj $header-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;
my PDF::Content::FontObj $body-font = $pdf.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;

    temp $gfx.actual-text = '';
    $tag = $gfx.mark: Header1, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
        .tag: Artifact, {
            .say: '_' x 10, :position[50, 117]
        }
    }

    is $tag.name, 'H1', 'mark tag name';
    is $tag.mcid, 0, 'mark tag mcid';
    is-deeply $gfx.actual-text.lines, ('Header text',), '$.actual-text';

    $tag = $gfx.mark: Paragraph, {
        .say('Paragraph that contains a figure', :position[50, 100], :font($body-font), :font-size(12));

        .tag: Figure, {
            my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
            .do: $img, :position[50,70];
        }

        .tag: Span, :Lang<es-MX>, {
            .say('Hasta la vista', :position[50, 80]);
        }
        .tag: ReversedChars, {
            .say: 'Hi';
        }

        throws-like {
            .mark: Span, {
                .say: 'Whoops';
            }
        }, X::PDF::Content::OP::BadNesting::MarkedContent;

    }

    is $tag.name, 'P', 'outer tag name';
    is $tag.kids[0].name, 'Figure', 'inner tag name';
    is $tag.descendants>>.name.join(','), 'P,Figure,Span,ReversedChars';
    is-deeply $gfx.actual-text.lines, ('Header text', 'Paragraph that contains a figure', 'Hasta la vista', 'iH'), '$.actual-text';
}

is $page.gfx.tags.gist, '<H1 MCID="0"><Artifact/></H1><P MCID="1"><Figure/><Span Lang="es-MX"/><ReversedChars/></P>';

# ensure consistant document ID generation
$pdf.id = $*PROGRAM.basename.fmt('%-16.16s');

lives-ok { $pdf.save-as: "t/tags.pdf" }

# check we can re-read tagged content

$pdf .= open: "t/tags.pdf";

is $pdf.page(1).render.tags.gist, '<H1 MCID="0"><Artifact/></H1><P MCID="1"><Figure/><Span Lang="es-MX"/><ReversedChars/></P>';

done-testing;
