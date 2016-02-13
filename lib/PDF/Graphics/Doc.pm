use v6;

use PDF::DAO::Doc;

#| A minimal class for manipulating PDF graphical content
class PDF::Graphics::Doc
    is PDF::DAO::Doc {

    use PDF::DAO::Tie;
    use PDF::DAO::Tie::Hash;

    use PDF::DAO::Stream;

    use PDF::Graphics::Contents;
    use PDF::Graphics::Paged;
    use PDF::Graphics::PageTree;
    use PDF::Graphics::Resourced;
    use PDF::Graphics::ResourceDict;

    role Resources
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::ResourceDict {
	    has PDF::Graphics::Image @.Image is entry;
    }

    role Page
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::Contents
	does PDF::Graphics::Paged
	does PDF::Graphics::Resourced {

	has Resources $.Resources is entry(:inherit);

	my subset StreamOrArray of Any where PDF::DAO::Stream | Array;
	has StreamOrArray $.Contents is entry;
    }

    role Pages
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::Paged
	does PDF::Graphics::Resourced
	does PDF::Graphics::PageTree {

	has Resources $.Resources is entry(:inherit);

	has PDF::Graphics::Paged @.Kids is entry(:required, :indirect);
        has UInt $.Count is entry(:required);
    }

    role Catalog
	does PDF::DAO::Tie::Hash
	does PDF::Graphics::Resourced {
	has Pages $.Pages is entry(:required, :indirect);
    }

    has Catalog $.Root is entry(:required, :indirect);
}
