use v6;
use Test;
plan 2;
use lib 't';
use PDF::Content::Color :rgb;
use PDF::Content::FontObj;
use PDFTiny;

my PDFTiny $pdf .= new;

$pdf.media-box = [0, 0, 400, 120];
my PDFTiny::Page $page = $pdf.add-page;

$page.graphics: {
    my PDF::Content::FontObj $font = .core-font( :family<Helvetica> );
    my PDFTiny::XObject-Form $form = .xobject-form(:BBox[0, 0, 95, 25]);
    $form.graphics: {
        # Set a background color
        .tag: 'P', {
            .FillColor = rgb(.8, .9, .9);
            .Rectangle: |$form<BBox>;
            .paint: :fill;
            .font = $font;
            .FillColor = rgb(1, .3, .3);  # reddish
            .say("Simple Form", :position[2, 5]);
        }
    }
    is $form.gfx.tags.map(*.gist).join, '<P/>';
    # display a simple form a couple of times
    .do($form, :position(10, 10));
    .transform: :translate(10,40), :rotate(.1), :scale(.75);
    .do($form, :position(10, 10));
}

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16s').substr(0,16);

lives-ok {$pdf.save-as: "t/forms.pdf"};
