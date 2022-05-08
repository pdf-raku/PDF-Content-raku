use v6;
use Test;
plan 3;

use lib 't';
use PDF::Content::Page;
use PDF::Content::PageTree;
use PDF::Content::Text::Style;
use PDFTiny;

my PDFTiny $pdf .= new;
my $Parent = $pdf.Root.Pages;
my PDF::Content::Page @pages;
todo 'not yet thread-safe (flapping)';
my $lived;
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
    $lived = True;
}, 'page insert race';

$pdf.add-page($_) for @pages;

if $lived {
    $lived = False;
    lives-ok {
        my @ = (1..$pdf.page-count).race(:batch(1)).map: -> $page-num {
            $pdf.page($page-num).text: {
                .text-position = 50, 200;
                .say: "Finish Page $page-num";
            }
        }
        $lived = True;
    }, 'page update race';
}

unless $lived {
    skip-rest "can't continue after failures";
    exit 0;
}

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as('t/threads.pdf'); }, 'save-as';

