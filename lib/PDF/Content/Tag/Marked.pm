use PDF::Content::Tag;

unit class PDF::Content::Tag::Marked
    is PDF::Content::Tag;

use PDF::COS::Dict;

my subset PageLike of PDF::COS::Dict where .<Type> ~~ 'Page';
my subset XObjectFormLike of PDF::COS::Dict where .<Subtype> ~~ 'Form';
my subset TagOwner where PageLike|XObjectFormLike;

has TagOwner $.owner is required;
has UInt $.mcid is required; # marked content identifer

method build-struct-elem(:%nums) {
    my $elem := callsame();

    given $!owner {
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
    $elem<K> = $!mcid;
    $elem;
}
