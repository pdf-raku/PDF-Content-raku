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
has Hash $.props;
has UInt $.start is rw;
has UInt $.end is rw;
has Bool $.is-new is rw;  # tags not yet in the struct tree
has PDF::Content::Tag $.parent is rw; # hierarchical parent
our class Kids {...}
has Kids $.kids handles<AT-POS list children grep map> .= new;

submethod TWEAK(:$mcid) {
    $!props<MCID> = $_ with $mcid;
    for $!kids.children {
        when PDF::Content::Tag {

            with .parent {
                die "child already has a parent"
                unless $_ === self;
            }
            else {
                $_ = self;
            }
        }
    }
}
method add-kid(PDF::Content::Tag $kid) {
    $!kids.push: $kid;
    $kid.parent = self;
}
method mcid is rw {
    Proxy.new(
        FETCH => { .<MCID> with $!props },
        STORE => -> $, UInt $_ {
            $!props<MCID> = $_
        },
    );
}
method gist {
    my $atts = do with $.mcid {
        ' MCID="' ~ $_ ~ '"';
    }
    else {
        '';
    };

    $.kids
        ?? [~] flat("<{$.name}$atts>",
                    $!kids.map(*.gist),
                    "</{$.name}>")
        !! "<{$.name}$atts/>";
}

method content(PDF::COS::Dict :parent($P)!, :@struct-parents, :%nums) {
    my $elem = PDF::COS.coerce: %(
        :Type( :name<StructElem> ),
        :S( :$!name ),
        :$P,
    );


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

    $elem<K> = $.mcid // do with $!kids {
        my @k = .content(:parent($elem), :@struct-parents, :%nums);
        @k > 1 ?? @k !! @k[0];
    }

    $elem;
}

our class Kids {

    my subset Node where PDF::Content::Tag | Str;
    has PDF::Content::Tag @.open-tags;
    has PDF::Content::Tag $.closed-tag;
    has Node @.children handles<grep map AT-POS Bool>;
    has @.struct-parents;

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

    method !child-content($parent, |c) {
        [ @!children.map(*.content(:$parent, |c)) ];
    }

    method !root-content {
        die "unclosed tags: {@!open-tags.map(*.gist).join}"
            if @!open-tags;
        @!struct-parents = ();
        my PDF::COS::Dict $root = PDF::COS.coerce: { :Type( :name<StructTreeRoot> ) };
        if @!children {
            my UInt %nums{Any};
            my @k = self!child-content($root, :@!struct-parents, :%nums);
            $root<K> = +@k > 1 ?? @k !! @k[0];
            if %nums {
                my $n = 0;
                my @Nums;
                for %nums.sort {
                    @Nums.push: $n;
                    @Nums.push: .key;
                    $n += .value;
                }
                $root<ParentTree> = %( :@Nums );
            }
        }
        $root;
    }

    method content(PDF::COS::Dict :$parent, |c) {
        with $parent {
            self!child-content($_, |c)
        } else {
            self!root-content;
        }
    }

    method gist { @!children.map(*.gist).join }
}
