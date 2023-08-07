use v6;
#| tiny test class for boot-strapping of PDF::Lite, PDF::Class, etc
unit class PDFTiny;

use PDF;
also is PDF;

use PDF::Content::API;
also does PDF::Content::API;

use PDF::COS;
use PDF::COS::Tie;
use PDF::COS::Loader;
use PDF::COS::Util :from-ast;
use PDF::COS::Dict;
use PDF::COS::Stream;
use PDF::Content::Page;
use PDF::Content::PageNode;
use PDF::Content::PageTree;
use PDF::Content::ResourceDict;
use PDF::Content::Canvas;
use PDF::Content::Font::CoreFont;
use Method::Also;

my role ResourceDict
    does PDF::COS::Tie::Hash
    does PDF::Content::ResourceDict { }

our class XObject-Form
    is PDF::COS::Stream
    does PDF::Content::XObject['Form']
    does PDF::Content::Canvas {
	has ResourceDict $.Resources is entry;
}

our class XObject-Image
    is PDF::COS::Stream
    does PDF::Content::XObject['Image'] {
}

our class Tiling-Pattern is XObject-Form {};

my class PageNode
    is PDF::COS::Dict
    does PDF::Content::PageNode {

   has ResourceDict $.Resources is entry(:inherit);
   has $.Parent is entry;
   has Numeric (@.MediaBox, @.CropBox) is entry(:inherit,:len(4));
}
our class Page is PageNode does PDF::Content::Page {
    has Numeric (@.TrimBox, @.BleedBox, @.ArtBox) is entry(:len(4));
}
our class Pages is PageNode does PDF::Content::PageTree {
    has ResourceDict $.Resources is entry(:inherit);
    has PageNode @.Kids    is entry(:required, :indirect);
    has UInt $.Count       is entry(:required);
}
our role Catalog
    does PDF::COS::Tie::Hash {
    has Pages $.Pages is entry(:required, :indirect);

    method cb-finish {
	self.Pages.?cb-finish;
    }
}

has Catalog $.Root is entry(:required, :indirect);

my class Loader is PDF::COS::Loader {
    method owner { PDFTiny }
    constant %Classes = %( :Form(XObject-Form), :Image(XObject-Image), :Page(Page), :Pages(Pages) );
    multi method load-delegate(Hash :$dict! where { from-ast($_) ~~ 'Form'|'Image' with .<Subtype> }) {
	%Classes{ from-ast($dict<Subtype>) };
    }
    multi method load-delegate(Hash :$dict! where { from-ast($_) ~~ 'Page'|'Pages' with .<Type> }) {
	%Classes{ from-ast($dict<Type>) };
    }
    multi method load-delegate(Hash :$dict! where { from-ast($_) == 1 with .<PatternType> }) {
	Tiling-Pattern
    }
}
PDF::COS.loader = Loader;

method cb-init {
    self<Root> //= %(
	:Type( :name<Catalog> ),
	:Pages{ :Type( :name<Pages> ),
		:Kids[], :Count(0), },
    );
}

method Pages handles <page add-page delete-page insert-page page-count media-box crop-box bleed-box trim-box art-box bleed use-font rotate iterate-pages> {
    self.Root.Pages;
}

# restrict to to PDF format; avoid FDF etc
method open(|c) { nextwith( :type<PDF>, |c); }

# unimplemented in PDF::Content::Interface
