use v6;
use Test;
plan 5;

use lib 't';
use PDFTiny;
use PDF::Content::PageTree;
my PDFTiny $pdf .= new;
# check support for reading of PDF files with multi-level
# page nodes; including fetching by page number, update and iteration.
# writing of multi-level page nodes is not yet supported, so we need to
# artifically create a multi-level page tree
my $page-number;
sub add-page($node) {
    my $page = $node.add-page;
    $page-number++;
    $page.graphics: {
        .say: "Page $page-number", :position[50, 600], :font-size(18);
    }
    $page;
}

my PDFTiny::Page $first-page = $pdf.add-page;

my PDF::Content::PageTree:D $child .= pages-fragment;
my PDFTiny::Page:D @middle-pages = (^3).map: {$child.add-page};
$pdf.Pages.add-pages: $child;

my PDF::Content::PageTree:D $grand-child = $child.add-pages;
my PDFTiny::Page:D @bottom-pages = (^3).map: {$grand-child.add-page};
my PDFTiny::Page:D @top-pages    = (^3).map: {$pdf.add-page};

subtest 'tree structure', {
    my $root := $pdf.Pages;
    # up
    is-deeply @bottom-pages.head.Parent, $grand-child;
    is-deeply $grand-child.Parent, $child;
    is-deeply $child.Parent, $root;
    # counts
    is-deeply $grand-child.Count, 3;
    is-deeply $child.Count, 6;
    is-deeply $root.Count, 10;
    # down
    is-deeply $root.Kids[0], $first-page;
    is-deeply $root.Kids[1], $child;
    is-deeply $root.Kids[1].Kids[3], $grand-child;
    is-deeply $root.Kids[1].Kids[3].Kids[0], @bottom-pages.head;
}

sub expected-page(UInt $_) {
    when 1 { $first-page }
    when 2..4 { @middle-pages[$_ - 2] }
    when 5..7 { @bottom-pages[$_ - 5] }
    when 8..10 { @top-pages[$_ - 8] }
}

my $n = $pdf.page-count;
is $n, 10;

subtest 'pages by page number', { 
    for 1..10 {
        ok $pdf.page($_) === expected-page($_), "page number $_";
    }
}

subtest 'iterate-pages', {
    plan 10;
    $page-number = 0;
    for $pdf.iterate-pages {
        $page-number++;
        ok $_ === expected-page($page-number), "page iteration $page-number";
    }
}

$pdf.id = $*PROGRAM-NAME.fmt('%-16.16s');
lives-ok { $pdf.save-as: "t/page-tree.pdf" }
