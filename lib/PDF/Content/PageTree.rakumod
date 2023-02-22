use PDF::Content::Resourced;

role PDF::Content::PageTree
    does PDF::Content::Resourced {

    use PDF::Content::Page;
    use PDF::Content::PageNode;
    use PDF::COS::Dict;
    use PDF::COS::Name;
    use Method::Also;

    my subset LeafNode of PDF::Content::PageTree where .Count == + .Kids && .[0] ~~ PDF::Content::PageNode;
    sub name(PDF::COS::Name() $_) { $_ }

    method page-fragment  { PDF::COS::Dict.COERCE: %( :Type( name 'Page'), ) }
    method pages-fragment { PDF::COS::Dict.COERCE: %( :Type( name 'Pages' ), :Count(0), :Kids[], ) }

    #| add new last page
    method add-page(::?ROLE:D: PDF::Content::Page:D $page = $.page-fragment) {

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
    method add-pages(::?ROLE:D: ::?ROLE:D $pages = $.pages-fragment) {
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
    multi method page(::?ROLE:D: UInt $page-num) {
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

    # build an flattened index of indirect references to pages
    method page-index {
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

    method pages {
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

    # allow array indexing of pages $pages[9] :== $.pages.page(10);
    method AT-POS(UInt $pos) is rw {
	# vivify next page
	self.add-page
	   if $pos == self<Count>;
        self.page($pos + 1)
    }

    method cb-finish {
        my Array $kids = self.Kids;
        $kids[$_].cb-finish
            for $kids.keys;
    }

}
