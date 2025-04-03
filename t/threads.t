use v6;
use Test;
plan 3;

use lib 't';
use PDF::Content::Page;
use PDF::Content::PageTree;
use PDFTiny;

my PDFTiny $pdf .= new;
my $cfont = $pdf.core-font('Courier');
my @fonts = <Courier Times-Roman Helvetica Times-Italic>.map: { $pdf.core-font($_) }
my PDF::Content::Page @pages;
lives-ok {
    @pages = (1..20).hyper(:batch(1)).map: -> $page-num {
        my PDF::Content::Page:D $page = PDF::Content::PageTree.page-fragment;
        $page.graphics: {
            .font = $cfont;
            .say: "Page $page-num", :position[50, 700];
            my $y = 650;
            @fonts.map: -> $font {
                .font = $font;
                .say: '';
                .say: q:to"TEXT", :width(300), :position[50, $y];
                Lorem ipsum dolor sit amet, consectetur adipiscing elit,
                sed do eiusmod tempor incididunt ut labore et dolore
                magna aliqua.
                TEXT
                $y -= 80;
            }
        }
        $page;
    }
}, 'page insert race';

$pdf.add-page($_) for @pages;

lives-ok {
    my @ = (1..$pdf.page-count).race(:batch(1)).map: -> $page-num {
        my $page = $pdf.page($page-num);
        $page.text: {
            .text-position = 50, 200;
            .font = $cfont;
            .print: "Finish ";
            .font = @fonts[1];
            .say: "Page $page-num";
        }
        $page.finish;
    }
}, 'page update race';

# ensure consistant document ID generation
$pdf.id = $*PROGRAM.basename.fmt('%-16.16s');

lives-ok { $pdf.save-as('t/threads.pdf'); }, 'save-as';

