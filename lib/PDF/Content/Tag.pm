use v6;

unit class PDF::Content::Tag;

use PDF::COS;
use PDF::COS::Dict;
use Method::Also;

has Str $.name is required;
has Str $.op;
has Hash $.atts;
has UInt $.start is rw;
has UInt $.end is rw;
has Bool $.is-new is rw;  # tags not yet in the struct tree
has PDF::Content::Tag $.parent is rw; # hierarchical parent
our class Set {...}
has Set $.kids handles<AT-POS list grep map tags children> .= new;

method add-kid(PDF::Content::Tag $kid) {
    $!kids.push: $kid;
    $kid.parent = self;
}

method !atts-gist {
    with $!atts {
        my %a = $_;
        %a<MCID> = $_ with self.?mcid;
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

    if $.kids {
        $elem<K> = do given $.kids {
            my @k = .build-struct-elems($elem, :%nums);
            @k > 1 ?? @k !! @k[0];
        }
    }

    if $!atts {
        my Str %dict = $!atts.List;
        $elem<A> = PDF::COS.coerce: :%dict;
    }

    $elem;
}

method take-descendants {
    take self;
    $!kids.take-descendants;
}
method descendant-tags { gather self.take-descendants }

method build-struct-tree {
    .build-struct-tree
        given PDF::Content::Tag::Set.new: :tags[self];
}

our class Set {

    my subset Node where PDF::Content::Tag | Str;
    has Node @.tags handles<grep map AT-POS Bool shift push elems>;
    method  children { @!tags }
    method take-descendants { @!tags.grep(PDF::Content::Tag).map(*.take-descendants) }
    method descendant-tags { gather self.take-descendants }

    method build-struct-elems($parent, |c) {
        [ @!tags.map(*.build-struct-elem(:$parent, |c)).grep(*.defined) ];
    }

    method build-struct-tree {
        my PDF::COS::Dict $struct-tree = PDF::COS.coerce: { :Type( :name<StructTreeRoot> ) };
        my @Nums;

        if @!tags {
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

    method gist { @!tags.map(*.gist).join }
}
