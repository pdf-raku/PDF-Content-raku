use v6;

class PDF::Content::Tag {
    has Str $.name;
    has Hash $.props;
    has UInt $.start;
    has UInt $.end is rw;
    has PDF::Content::Tag $.parent is rw;
    has PDF::Content::Tag @.children is rw handles<push AT-POS>;
    submethod TWEAK(:$mcid) {
        $!props<MCID> = $_ with $mcid;
    }
    method mcid is rw {
        Proxy.new(
            FETCH => sub ($) { .<MCID> with $!props },
            STORE => sub ($,UInt $_) {
                $!props<MCID> = $_
            },
        );
    }
    method gist {
        @!children
        ?? [~] flat("<{$.name}>",
                    @!children.map(*.gist),
                    "</{$.name}>")
        !! "<{$.name}/>";
    }
}
