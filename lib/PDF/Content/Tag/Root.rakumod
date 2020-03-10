use PDF::Content::Tag;
class PDF::Content::Tag::Root
    is PDF::Content::Tag {

    use PDF::COS;
    use PDF::COS::Dict;

    method build-struct-tree {
        my %parents{Any};
        my PDF::COS::Dict $struct-tree = PDF::COS.coerce: { :Type( :name<StructTreeRoot> ) };

        if self.tags {
            my @k = $.kids.build-struct-kids($struct-tree, :%parents);
            if @k {
                $struct-tree<K> = +@k > 1 ?? @k !! @k[0];
            }
            if %parents {
                # build a simple flat number tree
                my @Nums;
                my $n = 0;
                for %parents.keys -> $obj {
                    my $parent := %parents{$obj};
                    if $parent ~~ Array {
                        $obj<StructParents> = $n;
                    }
                    else {
                        $obj<StructParent> = $n;
                    }
                    @Nums.push: $n++;
                    @Nums.push: $parent;
                }
                $struct-tree<ParentTree> = %( :@Nums );
            }
        }

        $struct-tree;
    }

}
