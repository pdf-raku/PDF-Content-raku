use PDF::Content::Tag;

unit class PDF::Content::Tag::Marked
    is PDF::Content::Tag;

use PDF::COS::Dict;

my subset PageLike of Hash where .<Type> ~~ 'Page';
my subset XObjectFormLike of Hash where .<Subtype> ~~ 'Form';
my subset TagOwner where PageLike|XObjectFormLike;

has TagOwner $.owner is required;
has UInt $.mcid is rw; # marked content identifer

method build-struct-kids($elem, :%nums) {
    do with $!mcid -> $mcid {
        given $!owner {
            when PageLike {
                my $pg := $_;
                $elem<Pg> = $pg;
                given %nums{$pg} {
                    $_ = $mcid if !.defined || $_ < $mcid;
                }
            }
            when XObjectFormLike {
                warn "todo: tagged content handling of XObject forms";
            }
            default {
                warn "todo: tagged content items of type: {.WHAT.perl}";
            }
        }
        [$mcid;]
    }
    else {
        []
    }
}

method build-struct-elem(:%nums) {
    my $elem := callsame();
    $elem<K>:exists ?? $elem !! Mu;
}
