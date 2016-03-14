use v6;

use PDF::DAO::Doc;

#| A minimal class for manipulating PDF graphical content
class PDF::Basic::Doc
    is PDF::DAO::Doc {

    use PDF::DAO::Tie;
    use PDF::DAO::Tie::Hash;

    use PDF::DAO::Stream;

    use PDF::Basic::Graphics;
    use PDF::Basic::Font;
    use PDF::Basic::Page;
    use PDF::Basic::PageNode;
    use PDF::Basic::PageTree;
    use PDF::Basic::Resourced;    
    use PDF::Basic::ResourceDict;

    role Resources
	does PDF::DAO::Tie::Hash
	does PDF::Basic::ResourceDict {
	    has PDF::DAO::Stream %.XObject is entry;
            has PDF::Basic::Font %.Font is entry;
    }

    role Page
	does PDF::DAO::Tie::Hash
	does PDF::Basic::Page
	does PDF::Basic::PageNode {

 	has Resources $.Resources is entry(:inherit);
	#| inheritable page properties
	has Numeric @.MediaBox is entry(:inherit,:len(4));
	has Numeric @.CropBox is entry(:inherit,:len(4));
	has Numeric @.BleedBox is entry(:len(4));
	has Numeric @.TrimBox is entry(:len(4));
	has Numeric @.ArtBox is entry(:len(4));
	
	my subset StreamOrArray of Any where PDF::DAO::Stream | Array;
	has StreamOrArray $.Contents is entry;

	method to-xobject(|c) {

	    my role XObject-Form
		does PDF::DAO::Tie::Hash
		does PDF::Basic::Resourced
		does PDF::Basic::Graphics {
		    has Resources $.Resources is entry;
	    }

	    PDF::Basic::Page.to-xobject(self, :coerce(XObject-Form), |c);
	}
    }

    role Pages
	does PDF::DAO::Tie::Hash
	does PDF::Basic::PageNode
	does PDF::Basic::PageTree {

	has Resources $.Resources is entry(:inherit);
	#| inheritable page properties
	has Numeric @.MediaBox is entry(:inherit,:len(4));
	has Numeric @.CropBox is entry(:inherit,:len(4));

	has Page @.Kids is entry(:required, :indirect);
        has UInt $.Count is entry(:required);
    }

    role Catalog
	does PDF::DAO::Tie::Hash {
	has Pages $.Pages is entry(:required, :indirect);

	method cb-finish {
	    self.Pages.?cb-finish;
	}

    }

    has Catalog $.Root is entry(:required, :indirect);

    method cb-init {
	self<Root> //= { :Type( :name<Catalog> ), :Pages{ :Type( :name<Pages> ), :Kids[], :Count(0), } };
    }

    multi method page() {
	self.?Root.?Pages
    }

    multi method page(|c) is default {
	self.Root.Pages.page(|c)
    }

    multi method FALLBACK(Str $meth where { self.?Root.?Pages.can($meth) }, |c) {
        self.WHAT.^add_method($meth,  method (|a) { self.Root.Pages."$meth"(|a) } );
        self."$meth"(|c);
    }

    multi method FALLBACK(Str $method, |c) is default {
	die X::Method::NotFound.new( :$method, :typename(self.^name) );
    }

}
