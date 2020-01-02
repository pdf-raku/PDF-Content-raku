use v6;
use Test;
plan 1;

use lib 't/lib';
use PDFTiny;
use PDF::Content::Tag;

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

#
# under construction. manually finish page and StructTreeRoot;
# todo * /Nums entry in StructTreeRoot /StructParents entry in Page
my $kids = $gfx.tags;

my $doc = PDF::Content::Tag.new: :name<Document>, :$kids;
my $root = PDF::Content::Tag::Kids.new: :tags[$doc];

my $content = $root.content;
$pdf.Root<StructTreeRoot> = $content;

lives-ok {$pdf.save-as: "t/tags.pdf";}

done-testing;
