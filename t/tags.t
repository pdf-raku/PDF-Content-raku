use v6;
use Test;
plan 1;

use lib 't/lib';
use PDFTiny;
use PDF::Content::Tag;

# ensure consistant document ID generation
srand(123456);

my PDFTiny $pdf .= new;

my PDFTiny::Page $page = $pdf.add-page;
my $gfx = $page.gfx;

my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );
my $body-font = $page.core-font( :family<Helvetica> );

$gfx.tag: 'H1', {
    .text: {
        .text-position = 50, 100;
        .font = $header-font, 14;
        .say('Header text');
    }
};

$gfx.tag: 'P', {
    .text: {
        .text-position = 70, 100;
        .font = $body-font, 12;
        .say('Some body text');
    }
};

my $kids = $gfx.tags;

# finishing work; normally undertaken by the API

my $doc = PDF::Content::Tag.new: :name<Document>, :$kids;
my $root = PDF::Content::Tag::Kids.new: :children[$doc];
my $content = $root.content;
$pdf.Root<StructTreeRoot> = $content;
($pdf.Root<MarkedInfo> //= {})<Marked> = True;
for $root.struct-parents {
    .key<StructParents> = .value;
}

lives-ok {$pdf.save-as: "t/tags.pdf";}

done-testing;
