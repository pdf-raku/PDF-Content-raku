use v6;
use PDF;
use PDF::Content::Interface;
class PDFTiny is PDF does PDF::Content::Interface {
    # tiny test class for boot-strapping of PDF::Lite, PDF::Class, etc
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
    use PDF::Content::Resourced;
    use PDF::Content::XObject;
    my role ResourceDict
	does PDF::COS::Tie::Hash
	does PDF::Content::ResourceDict { }
    our class XObject-Form
        is PDF::COS::Stream
        does PDF::Content::XObject['Form']
        does PDF::Content::Resourced
        does PDF::Content::Graphics {
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
    }
    our class Page is PageNode does PDF::Content::Page {
	has Numeric @.MediaBox is entry(:inherit,:len(4));
	has Numeric @.CropBox  is entry(:len(4));
	has Numeric @.TrimBox  is entry(:len(4));
	has Numeric @.BleedBox is entry(:len(4));
    }
    our class Pages is PageNode does PDF::Content::PageTree {
	has ResourceDict $.Resources is entry(:inherit);
	has Numeric @.MediaBox is entry(:inherit,:len(4));
	has Numeric @.CropBox  is entry(:inherit,:len(4));
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

    method Pages handles <page add-page delete-page insert-page page-count media-box crop-box bleed-box trim-box art-box core-font use-font rotate> {
        self.Root.Pages;
    }

    # restrict to to PDF format; avoid FDF etc
    method open(|c) { nextwith( :type<PDF>, |c); }
}
