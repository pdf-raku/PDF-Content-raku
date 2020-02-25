use PDF::Content::Tag;

unit class PDF::Content::Tag::Mark
    is PDF::Content::Tag;

use PDF::COS;
my subset PageLike of Hash where .<Type> ~~ 'Page';

has $.owner is required;
has UInt $.start is rw;
has UInt $.end is rw;
has UInt $.mcid is rw; # marked content identifer

method build-struct-elem(:%nums) {
    with $!mcid -> $MCID {
        given PDF::COS.coerce: %(
            :Type( :name<MCR> ),
            :$MCID
        ) {
           .<Pg> = $!owner
               if $!owner ~~ PageLike;
           $_;
        }
    }
    else {
        fail "unmarked";
    }
}
