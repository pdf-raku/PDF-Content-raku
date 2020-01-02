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
has PDF::Content::Tag $.parent is rw; # heirarcheal parent

our class Kids {...}
has Kids $.kids handles<AT-POS list children grep map> .= new;

submethod TWEAK(:$mcid) {
    $!props<MCID> = $_ with $mcid;
    for $!kids.tags {
        with .parent {
            die "child already has a parent"
                unless $_ === self;
        }
        else {
            $_ = self;
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

method content(PDF::COS::Dict :parent($P)!) {
    my $elem = PDF::COS.coerce: %(
        :Type( :name<StructElem> ),
        :S( :$!name ),
        :$P,
    );
    $elem<K> = $_ with $.mcid;
    with $!owner {
        when PageLike {
            $elem<Pg> = $_;
        }
        when XObjectFormLike {
            warn "todo: tagged content handling of XObject forms";
        }
        default {
            warn "todo: tagged content items of type: {.WHAT.perl}";
        }
    }

    if $!kids {
        my @k =  $!kids.map(*.content(:parent($elem)));
        $elem<K> = @k > 1 ?? @k !! @k[0];
    }

    $elem;
}

our class Kids {

    has PDF::Content::Tag @.open-tags;
    has PDF::Content::Tag $.closed-tag;
    has PDF::Content::Tag @.tags handles<grep map AT-POS Bool>;

    proto method list(|c) is also<children> {*};
    multi method list(@tags = @!tags, :$flat! where .so) {
        flat @tags.map: {
            ($_,
             self.list(.grep(PDF::Content::Tag), :flat))
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

    method add-tag(PDF::Content::Tag $tag) is also<push> {
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
            my @k = @!tags.map(*.content(:parent($root), ));
            $root<K> = +@k > 1 ?? @k !! @k[0];
        }
        $root;
    }
}
