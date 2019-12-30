class PDF::Content::Tags {

    use PDF::Content::Tag;

    has PDF::Content::Tag @.open-tags;
    has PDF::Content::Tag @!tags;
    has PDF::Content::Tag $.closed-tag;
    proto method list(|c) handles<grep AT-POS> {*}
    multi method list(@tags = @!tags, :$flat! where .so) {
        flat @tags.map: {
            ($_,
             self.list(.children.grep(PDF::Content::Tag), :flat))
        }
    }
    multi method list is default { @!tags }

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

}
