use v6;
use Test;
plan 3;

use lib 't';
use PDF::Content::Page;
use PDF::Content::PageTree;
use PDFTiny;

my PDFTiny $pdf .= new;
my PDF::Content::Page @pages;
lives-ok {
    @pages = (1..20).race(:batch(1)).map: -> $page-num {
        my PDF::Content::Page:D $page = PDF::Content::PageTree.page-fragment;
        $page.text: {
            .text-position = 50, 400;
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
            .say: "Finish Page $page-num";
        }
    }
}, 'page update race';

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as('t/threads.pdf'); }, 'save-as';

