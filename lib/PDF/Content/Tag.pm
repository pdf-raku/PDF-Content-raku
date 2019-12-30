use v6;

class PDF::Content::Tag {
    has $.owner;
    has Str $.op is required;
    has Str $.name is required;
    has Hash $.props;
    has UInt $.start is rw;
    has UInt $.end is rw;
    has Bool $.is-new is rw;  # tags not yet in the struct tree
    has PDF::Content::Tag $.parent is rw;
    has @.children handles<AT-POS>;
    submethod TWEAK(:$mcid) {
        $!props<MCID> = $_ with $mcid;
    }
    method add-kid(PDF::Content::Tag $kid) {
        @!children.push: $kid;
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

        @!children
        ?? [~] flat("<{$.name}$atts>",
                    @!children.map(*.gist),
                    "</{$.name}>")
        !! "<{$.name}$atts/>";
    }
}
