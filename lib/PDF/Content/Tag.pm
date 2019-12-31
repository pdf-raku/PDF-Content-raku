use v6;

class PDF::Content::Tag {
    use PDF::COS;
    use PDF::COS::Dict;

    has Str $.name is required;
    has $.owner;
    has Str $.op;
    has Hash $.props;
    has UInt $.start is rw;
    has UInt $.end is rw;
    has Bool $.is-new is rw;  # tags not yet in the struct tree
    has PDF::Content::Tag $.parent is rw;
    has @.children handles<AT-POS>;
    submethod TWEAK(:$mcid) {
        $!props<MCID> = $_ with $mcid;
        for @!children {
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

    method content(PDF::COS::Dict :parent($P)!) {
        my $elem = PDF::COS.coerce: %(
            :Type( :name<StructElem> ),
            :S( :$!name ),
            :$P,
        );
        with $!owner {
            if .<Type> ~~ 'Page' {
                $elem<Pg> = $_;
            }
            else {
                warn "todo: tagged content items of type: {.WHAT.perl}";
            }
        }

        if @!children {
            my @k =  @!children.map(*.content(:parent($elem)));
            $elem<K> = @k > 1 ?? @k !! @k[0];
        }

        $elem;
    }
}
