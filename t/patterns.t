use v6;
use Test;
use lib 't';
use PDFTiny;

my PDFTiny $pdf .= new;
my PDFTiny::Page $page = $pdf.add-page;

lives-ok {
    $page.graphics: -> $gfx {
        my PDFTiny::Tiling-Pattern $pattern = $page.tiling-pattern(:BBox[0, 0, 25, 25], );
        $pattern.graphics: {
            .FillColor = :DeviceRGB[.7, .7, .9];
            .Rectangle(|$pattern<BBox>);
            .Fill;
            my $img = .load-image("t/images/lightbulb.gif");
            .do($img, :position[5, 5] );
        }
        $gfx.FillColor = $gfx.use-pattern($pattern);
        $gfx.Rectangle(0, 20, 100, 250);
        $gfx.Fill;
        $gfx.transform: :translate[110, 10];
        $gfx.Rectangle(0, 20, 100, 250);
        $gfx.Fill;
    }

    # ensure consistant document ID generation
    $pdf.id = $*PROGRAM.basename.fmt('%-16.16s');

    $pdf.save-as: "t/patterns.pdf";
};

done-testing;
