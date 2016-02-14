use v6;

use PDF::DAO::Doc;

#| A minimal class for manipulating PDF graphical content
class PDF::Graphics::Doc
    is PDF::DAO::Doc {

    use PDF::DAO::Tie;
    use PDF::DAO::Tie::Hash;

    use PDF::DAO::Stream;

    use PDF::Graphics::Contents;
    use PDF::Graphics::Page;
    use PDF::Graphics::PageNode;
    use PDF::Graphics::PageTree;
    use PDF::Graphics::ResourceDict;

    role Resources
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::ResourceDict {
	    has PDF::Graphics::Image @.Image is entry;
    }

    role Page
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::Page
	does PDF::Graphics::PageNode {

	has Resources $.Resources is entry(:inherit);
	#| inheritable page properties
	has Numeric @.MediaBox is entry(:inherit,:len(4));
	has Numeric @.CropBox is entry(:inherit,:len(4));

	my subset StreamOrArray of Any where PDF::DAO::Stream | Array;
	has StreamOrArray $.Contents is entry;
    }

    role Pages
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::PageNode
	does PDF::Graphics::PageTree {

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
    }

    has Catalog $.Root is entry(:required, :indirect);

    multi method FALLBACK(Str $meth where { self.?Root.?Pages>.can($meth) }, |c) {
        self.WHAT.^add_method($meth,  method (|a) { self.Root.Pages."$meth"(|a) } );
        self."$meth"(|c);
    }

    method cb-init {
	self<Root> //= { :Type( :name<Catalog> ), :Pages{ :Type( :name<Pages> ), :Kids[], } };
    }

}
