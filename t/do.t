use v6;
use Test;
plan 3;
use lib 't';
use PDF::Content::Color :rgb;
use PDF::Content::FontObj;
use PDF::Content::XObject;
use PDFTiny;

my PDFTiny $pdf .= new;

$pdf.media-box = [0, 0, 400, 120];
my PDFTiny::Page $page = $pdf.add-page;

$page.graphics: {
    my PDF::Content::FontObj $font = $pdf.core-font( :family<Helvetica> );
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
    my PDF::Content::XObject $jpeg .= open: "t/images/jpeg.jpg";
    # sanity check of form vs image positioning
    my @p1 = .do($form, :position(10, 30), :width(80), :height(30), :valign<top>);
    is-deeply @p1, [10, 0, 90, 30], 'form position';

    my @p2 = .do($jpeg, :position(100, 30), :width(80), :height(30), :valign<top>);
    is-deeply @p2, [100, 0, 180, 30], 'image position';

    # This should form a grid
    .do($form, :position(10, 50), :width(80), :height(30), :valign<center>);
    .do($jpeg, :position(100, 50), :width(80), :height(30), :valign<center>);
    .do($form, :position(10, 70), :width(80), :height(30), :valign<bottom>);
    .do($jpeg, :position(100, 70), :width(80), :height(30), :valign<bottom>);
}

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok {$pdf.save-as: "t/do.pdf"};
