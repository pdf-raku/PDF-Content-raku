use v6;
use Test;
plan 4;

use lib 't';
use PDFTiny;
use PDF::COS::Name;
use PDF::COS::Dict;
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
my $Type = PDF::COS::Name.COERCE: 'Pages';

my PDFTiny::Page $first-page = $pdf.&add-page;

role SimpleAddPage {
    method add-page {
        my PDFTiny::Page $page = PDF::COS::Dict.COERCE: { :Type( :name<Page> ) };
        self.Kids.push: $page;
	$page = self.Kids.tail;
	$page<Parent> = self.link;
        my $node = self;
        while $node.defined {
            $node<Count>++;
            $node = $node<Parent>;
        }
        $page;
    }
}

my $Parent = $pdf.Pages does SimpleAddPage;

my $child = PDF::COS::Dict.COERCE: { :$Type, :$Parent, :Count(0), :Kids[] }; 
$Parent.Kids.push: $child;
my @middle-pages = (^3).map: {$child.&add-page};

my $grand-child = PDF::COS::Dict.COERCE: { :$Type, :Parent($child), :Count(0), :Kids[] };
$child.Kids.push: $grand-child;
my @bottom-pages = (^3).map: {$grand-child.&add-page};
my @top-pages    = (^3).map: {$pdf.&add-page};

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
