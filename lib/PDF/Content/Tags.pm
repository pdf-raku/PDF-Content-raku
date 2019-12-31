class PDF::Content::Tags {

    use PDF::Content::Tag;
    use PDF::COS;
    use PDF::COS::Dict;

    has PDF::Content::Tag @.open-tags;
    has PDF::Content::Tag $.closed-tag;
    has PDF::Content::Tag @.tags;
    proto method tags(|c) handles<grep map AT-POS> {*}
    multi method tags(@tags = @!tags, :$flat! where .so) {
        flat @tags.map: {
            ($_,
             self.tags(.children.grep(PDF::Content::Tag), :flat))
        }
    }
    multi method tags is default { @!tags }

    method open-tag(PDF::Content::Tag $tag) {
        with @!open-tags.tail {
            .add-kid: $tag;
        }
        @!open-tags.push: $tag;
    }

    method close-tag {
	$!closed-tag = @!open-tags.pop;
        @!tags.push: $!closed-tag
            without $!closed-tag.parent;
        $!closed-tag;
    }

    method add-tag(PDF::Content::Tag $tag) {
        with @!open-tags.tail {
            .add-kid: $tag;
        }
        else {
            @!tags.push: $tag
        }
    }

    multi method content(PDF::COS::Dict :$parent!) {
        [ @!tags.map(*.content(:$parent)) ];
    }

    multi method content {
        my PDF::COS::Dict $root;
        die "unclosed tags: {@!open-tags.map(*.gist).join}"
            if @!open-tags;
        if @!tags {
            $root = PDF::COS.coerce: { :Type( :name<StructTreeRoot> ) };
            my @k = @!tags.map(*.content(:parent($root)));
            $root<K> = +@k > 1 ?? @k !! @k[0];
        }
    }

}
