use v6;

unit class PDF::Content::Tag;

use PDF::COS;
use PDF::COS::Dict;
use Method::Also;

my subset PageLike of PDF::COS::Dict where .<Type> ~~ 'Page';
my subset XObjectFormLike of PDF::COS::Dict where .<Subtype> ~~ 'Form';

has Str $.name is required;
has $.owner; # PDF element that contains this tag
has Str $.op;
has Hash $.atts;
has UInt $.start is rw;
has UInt $.end is rw;
has Bool $.is-new is rw;  # tags not yet in the struct tree
has UInt $.mcid is rw; # marked content identifer
has PDF::Content::Tag $.parent is rw; # hierarchical parent
our class Kids {...}
has Kids $.kids handles<AT-POS list children grep map> .= new;

method add-kid(PDF::Content::Tag $kid) {
    $!kids.push: $kid;
    $kid.parent = self;
}
method !atts-gist {
    with $!atts {
        my %a = $_;
        %a<MCID> = $_ with $.mcid;
        %a.pairs.sort.map({ " {.key}=\"{.value}\"" }).join: '';
    }
    else {
        '';
    }
}

method gist {
    my $atts = self!atts-gist();
    $.kids
        ?? [~] flat("<{$.name}$atts>",
                    $!kids.map(*.gist),
                    "</{$.name}>")
        !! "<{$.name}$atts/>";
}

method build-struct-elem(PDF::COS::Dict :parent($P)!, :%nums) {
    my $elem = PDF::COS.coerce: %(
        :Type( :name<StructElem> ),
        :S( :$!name ),
        :$P,
    );

    if $!atts {
        my Str %dict = $!atts.List;
        $elem<A> = PDF::COS.coerce: :%dict;
    }

    with $!owner {
        when PageLike {
            my $pg := $_;
            $elem<Pg> = $pg;
            do with $.mcid -> $mcid {
                given %nums{$pg} {
                    $_ = $mcid if !.defined || $_ < $mcid;
                }
            }
        }
        when XObjectFormLike {
            warn "todo: tagged content handling of XObject forms";
        }
        default {
            warn "todo: tagged content items of type: {.WHAT.perl}";
        }
    }

    $elem<K> = $.mcid // do given $!kids {
        my @k = .build-struct-elems($elem, :%nums);
        @k > 1 ?? @k !! @k[0];
    }

    $elem;
}

method take-descendants {
    take self;
    $!kids.take-descendants;
}
method descendant-tags { gather self.take-descendants }

method build-struct-tree {
    my $root = PDF::Content::Tag::Kids.new: :children[self];
    $root.build-struct-tree;
}

our class Kids {

    my subset Node where PDF::Content::Tag | Str;
    has PDF::Content::Tag @.open-tags;
    has PDF::Content::Tag $.closed-tag;
    has Node @.children handles<grep map AT-POS Bool>;

    method take-descendants { @!children.grep(PDF::Content::Tag).map(*.take-descendants) }
    method descendant-tags { gather self.take-descendants }

    method open-tag(PDF::Content::Tag $tag) {
        with @!open-tags.tail {
            .add-kid: $tag;
        }
        @!open-tags.push: $tag;
    }

    method close-tag {
	$!closed-tag = @!open-tags.pop;
        @!children.push: $!closed-tag
            without $!closed-tag.parent;
        $!closed-tag;
    }

    method add-tag(Node $node) is also<push> {
        with @!open-tags.tail {
            .add-kid: $node;
        }
        else {
            @!children.push: $node;
        }
    }

    method build-struct-elems($parent, |c) {
        [ @!children.map(*.build-struct-elem(:$parent, |c)) ];
    }

    method build-struct-tree {
        die "unclosed tags: {@!open-tags.map(*.gist).join}"
            if @!open-tags;
        my PDF::COS::Dict $struct-tree = PDF::COS.coerce: { :Type( :name<StructTreeRoot> ) };
        my @Nums;

        if @!children {
            my UInt %nums{Any};
            my @k = self.build-struct-elems($struct-tree, :%nums);
            $struct-tree<K> = +@k > 1 ?? @k !! @k[0];
            if %nums {
                my $n = 0;
                for %nums.sort {
                    my $parent := .key;
                    @Nums.push: $n;
                    @Nums.push: $parent;
                    $n += .value;
                }
                $struct-tree<ParentTree> = %( :@Nums );
            }
        }

        ($struct-tree, @Nums);
    }

    method gist { @!children.map(*.gist).join }
}
