[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [PageTree](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/PageTree)



methods related to page tree nodes

Description
-----------

This role contains methods for querying and manipulating page tree nodes in a PDF.

### Page Fragments

This class includes the methods:

  * `page-fragment` - create a detached page `pages-fragment` - create a detached page sub-tree

These stand-alone fragments aim to be thread-safe to support parallel construction of pages. The final PDF assembly needs to be synchronous.

```raku
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
```

Methods
-------

### method page-fragment

```raku
method page-fragment() returns PDF::Content::Page
```

produce a single page fragment, not attached to any PDF

### method pages-fragment

```raku
method pages-fragment() returns PDF::Content::PageNode
```

produce a page-tree fragment, not attached to any PDF

### method add-page

```raku
method add-page(
    PDF::Content::Page:D $page = Code.new
) returns PDF::Content::Page
```

add new last page

### method add-pages

```raku
method add-pages(
    PDF::Content::PageTree:D $pages = Code.new
) returns PDF::Content::PageTree
```

append page subtree

### method page

```raku
method page(
    Int $page-num where { ... } = 0
) returns PDF::Content::Page
```

$.page(0?) - adds a new page

### method page

```raku
method page(
    Int $page-num where { ... }
) returns PDF::Content::Page
```

traverse page tree

### method page-index

```raku
method page-index() returns Array
```

build flattened index of indirect references to pages

### method pages

```raku
method pages() returns Array
```

return all leaf pages for this page tree. or sub-tree

### method delete-page

```raku
method delete-page(
    Int $page-num where { ... }
) returns PDF::Content::Page
```

delete page from page tree

### method page-count

```raku
method page-count() returns UInt
```

return the number of pages

