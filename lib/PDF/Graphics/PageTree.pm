use v6;

use PDF::Graphics::Resourced;

role PDF::Graphics::PageTree
    does PDF::Graphics::Resourced {

    use PDF::Graphics::PageNode;
    use PDF::DAO;

    #| add new last page
    method add-page( $page? is copy ) {
        my $sub-pages = self.Kids[*-1]
            if self.Kids;

	if $page {
	    unless $page<Resources>:exists {
		# import resources, if inherited and outside our heirarchy
		my $resources = $page.Resources;
		$page<Resources> = $resources.clone
		    if $resources && $resources !=== self.Resources;
	    }
	}
	else {
	    $page = PDF::DAO.coerce: :dict{ :Type( :name<Page> ) };
	}

        if $sub-pages && $sub-pages.can('add-page') {
            $page = $sub-pages.add-page( $page )
        }
        else {
            self.Kids.push: $page;
	    $page = self.Kids[*-1];
	    $page<Parent> = self.link;
        }

        self<Count>++;
        $page
    }

    #| append page subtree
    method add-pages( PDF::Graphics::PageNode $pages ) {
	self<Count> += $pages<Count>;
	self<Kids>.push: $pages;
	$pages<Parent> = self;
        $pages;
    }

    #| $.page(0) or $.page(-1) adds a new page
    multi method page(Int $page-num where $page-num == 0|-1
	--> PDF::Graphics::PageNode) {
        self.add-page;
    }

    #| terminal page node - no children
    multi method page(Int $page-num where { self.Count == + self.Kids && $_ <= + self.Kids}) {
        self.Kids[$page-num - 1];
    }

    #| traverse page tree
    multi method page(Int $page-num where { $page-num > 0 && $page-num <= self<Count> }) {
        my Int $page-count = 0;

        for self.Kids.keys {
            my $kid = self.Kids[$_];

            if $kid.can('page') {
                my Int $sub-pages = $kid<Count>;
                my Int $sub-page-num = $page-num - $page-count;

                return $kid.page( $sub-page-num )
                    if $sub-page-num > 0 && $sub-page-num <= $sub-pages;

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

    #| delete page from page tree
    multi method delete-page(Int $page-num where { $page-num > 0 && $page-num <= self<Count>},
	--> PDF::Graphics::PageNode) {
        my $page-count = 0;

        for self.Kids.keys -> $i {
            my $kid = self.Kids[$i];

            if $kid.can('page') {
                my $sub-pages = $kid<Count>;
                my $sub-page-num = $page-num - $page-count;

                if $sub-page-num > 0 && $sub-page-num <= $sub-pages {
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

    # allow array indexing of pages $pages[9] :== $.pages.page(10);
    method AT-POS($pos) is rw {
        self.page($pos + 1)
    }

}
