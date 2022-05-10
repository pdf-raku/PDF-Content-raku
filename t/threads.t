use v6;
use Test;
plan 3;

use lib 't';
use PDF::Content::Page;
use PDF::Content::PageTree;
use PDFTiny;

my PDFTiny $pdf .= new;
my $font = $pdf.core-font('Courier');
my $font2 = $pdf.core-font('Times-Roman');
my PDF::Content::Page @pages;
lives-ok {
    @pages = (1..20).race(:batch(1)).map: -> $page-num {
        my PDF::Content::Page:D $page = PDF::Content::PageTree.page-fragment;
        $page.text: {
            .text-position = 50, 400;
            .font = $font;
            .say: "Page $page-num";
            .say: '';
            .say: q:to"TEXT", :width(300);
            Lorem ipsum dolor sit amet, consectetur adipiscing elit,
            sed do eiusmod tempor incididunt ut labore et dolore
            magna aliqua.
            TEXT
        }
        $page;
    }
}, 'page insert race';

$pdf.add-page($_) for @pages;

lives-ok {
    my @ = (1..$pdf.page-count).race(:batch(1)).map: -> $page-num {
        $pdf.page($page-num).text: {
            .text-position = 50, 200;
            .print: "Finish ";
            .font = $font2;
            .say: "Page $page-num";
        }
    }
}, 'page update race';

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as('t/threads.pdf'); }, 'save-as';

