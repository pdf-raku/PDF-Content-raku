#| methods related to page tree nodes
unit role PDF::Content::PageTree;

=begin pod

=head2 Description

This role contains methods for querying and manipulating page tree
nodes in a PDF.

=head3 Page Fragments

This class includes the methods:

=item `page-fragment` - create a detached page
`pages-fragment` - create a detached page sub-tree

These stand-alone fragments aim to be thread-safe to support parallel construction of pages. The final PDF assembly needs to be synchronous.

=begin code :lang<raku>
use PDF::Content::Page;
use PDF::Content::PageTree;
use lib 't';
use PDFTiny;

my PDFTiny $pdf .= new;
my PDF::Content::Page @pages;

@pages = (1..20).hyper(:batch(1)).map: -> $page-num {
    my PDF::Content::Page:D $page = PDF::Content::PageTree.page-fragment;
    $page.text: {
        .text-position = 50, 400;
        .say: "Page $page-num";
    }
    $page.finish;
    $page;
}

$pdf.add-page($_) for @pages;
=end code

=head2 Methods

=end pod

use PDF::Content::Resourced;
also does PDF::Content::Resourced;

use PDF::Content::Page;
use PDF::Content::PageNode;
use PDF::COS::Dict;
use PDF::COS::Name;
use Method::Also;

my subset LeafNode of PDF::Content::PageTree where .Count == + .Kids && .[0] ~~ PDF::Content::PageNode;
sub name(PDF::COS::Name() $_) { $_ }

#| produce a single page fragment, not attached to any PDF
method page-fragment returns PDF::Content::Page { PDF::COS::Dict.COERCE: %( :Type( name 'Page'), ) }

#| produce a page-tree fragment, not attached to any PDF
method pages-fragment returns PDF::Content::PageNode { PDF::COS::Dict.COERCE: %( :Type( name 'Pages' ), :Count(0), :Kids[], ) }

#| add new last page
method add-page(::?ROLE:D: PDF::Content::Page:D $page = $.page-fragment --> PDF::Content::Page) {

    self.Kids.push: $page;
    $page<Parent> = self.link;
    my $node = self;
    my $n = 0;
    while $node.defined {
        $node<Count>++;
        $node = $node<Parent>;
        die "maximum page tree depth exceeded"
            if ++$n > 1000;
    }

    $page
}

#| append page subtree
method add-pages(::?ROLE:D: ::?ROLE:D $pages = $.pages-fragment --> ::?ROLE:D) {
    self.Kids.push: $pages;
    $pages<Parent> = self.link;

    if $pages<Count> -> $count {
        my $node = self;
        my $n = 0;
        while $node.defined {
            $node<Count> += $count;
            $node = $node<Parent>;
            die "maximum page tree depth exceeded"
                if ++$n > 1000;
        }
    }
    $pages;
}

#| $.page(0?) - adds a new page
multi method page(::?ROLE:D: Int $page-num where 0 = 0 --> PDF::Content::Page) {
    self.add-page;
}

#| traverse page tree
multi method page(::?ROLE:D: UInt $page-num --> PDF::Content::Page) {
    my Int $page-count = 0;

    for self.Kids.keys {
        my $kid = self.Kids[$_];

        if $kid.does($?ROLE) {
            my UInt $sub-pages = $kid<Count>;
            my UInt $sub-page-num = $page-num - $page-count;

            return $kid.page( $sub-page-num )
                if 0 < $sub-page-num <= $sub-pages;

            $page-count += $sub-pages
        }
        else {
            $page-count++;
            return $kid
                if $page-count == $page-num;
        }
    }

    die "unable to locate page: $page-num";
}

multi method page(Int $page-num) {
    die "no such page: $page-num";
}

#| build flattened index of indirect references to pages
method page-index returns Array {
    my @index;
    if self ~~ LeafNode {
        @index = self.Kids.values
    }
    else {
        my $kids := self.Kids;
        for ^+$kids {
            given $kids[$_] {
                when PDF::Content::PageTree { @index.append: .page-index }
                when PDF::Content::Page     { @index.push: .ind-ref }
                default { die "unexpected object in page tree: {.raku}"; }
            }
        }
    }
    @index;
}

#| return all leaf pages for this page tree. or sub-tree
method pages returns Array {
    my @pages;
    my $kids := self.Kids;
    for ^+$kids {
        given $kids[$_] {
            when PDF::Content::PageTree { @pages.append: .pages }
            when PDF::Content::Page     { @pages.push: $_ }
            default { die "unexpected object in page tree: {.raku}"; }
        }
    }
    @pages;
}

#| delete page from page tree
multi method delete-page(UInt $page-num --> PDF::Content::Page) {
    my $page-count = 0;

    for self.Kids.keys -> $i {
        my $kid = self.Kids[$i];

        if $kid.does($?ROLE) {
            my UInt $sub-pages = $kid<Count>;
            my Int $sub-page-num = $page-num - $page-count;

            if 0 < $sub-page-num <= $sub-pages {
                # found in descendant
                self<Count>--;
                return $kid.delete-page( $sub-page-num );
            }

            $page-count += $sub-pages
        }
        else {
            $page-count++;
            if $page-count == $page-num {
                # found at leaf
                self<Kids>.splice($i, 1);
                self<Count>--;
                return $kid
            }
        }
    }

    die "unable to locate page: $page-num";
}

#| return the number of pages
method page-count is also<Int> returns UInt { self.Count }

# iterates all child page nodes
method iterate-pages(PDF::Content::PageTree:D $node:) {
    my class PageIterator {
        also does Iterator;
        also does Iterable;
        has PDF::Content::PageTree:D $.node is required;
        has PDF::Content::Page $!page;
        has Int $!i = -1;
        has UInt $!n;
        has PageIterator $.kid;
        submethod TWEAK {
            $!n = +$!node<Kids>;
            self!get-next;
        }
        method !get-next {
            $!kid = Nil;
            $!page = Nil;
            if ++$!i < $!n {
                given $!node<Kids>[$!i] {
                    if .does(PDF::Content::PageTree) {
                        $!kid = PageIterator.new: :node($_);
                    }
                    else {
                        $!page = $_;
                    }
                }
            }
        }
        method pull-one {
            my $rv = IterationEnd;
            with $!page {
                $rv = $_;
                self!get-next;
            }
            else {
                with $!kid {
                    $rv = .pull-one;
                    unless $rv.does(PDF::Content::Page) {
                        self!get-next;
                        $rv = self.pull-one;
                    }
                }
            }
            $rv;
        }
        method iterator { self }
    }
    PageIterator.new: :$node;
}

# return zero offset page, i.e. $pages[0] === $pages.page(1);
method AT-POS(UInt $pos) is rw {
    # vivify next page
    self.add-page
       if $pos == self<Count>;
    self.page($pos + 1)
}

# finish a page tree for serialization purposes
method cb-finish {
    my Array $kids = self.Kids;
    $kids[$_].cb-finish
        for $kids.keys;
}
