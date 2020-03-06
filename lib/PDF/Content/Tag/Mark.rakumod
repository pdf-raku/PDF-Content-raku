use PDF::Content::Tag;

unit class PDF::Content::Tag::Mark
    is PDF::Content::Tag;

use PDF::COS;
use PDF::COS::Stream;

my subset PageLike of Hash where .<Type> ~~ 'Page';
my subset Owner where PageLike|PDF::COS::Stream;

has Owner $.owner is required;
has UInt $.start is rw;
has UInt $.end is rw;
has UInt $.mcid is rw; # marked content identifer
has PDF::COS::Stream $.content;

method content { $!content // $!owner }

method build-struct-elem(:%nums) {
    with $!mcid -> $MCID {
        fail "only applicable to page content"
            unless $!owner ~~ PageLike;
        given PDF::COS.coerce: %(
            :Type( :name<MCR> ),
            :$MCID,
            :Pg($!owner),
        ) -> $mcr {
           my $obj = do with $!content {
               $mcr<Stm> = $_;
           }
           else {
               $!owner;
           }
           given %nums{$obj} {
               $_ = $MCID if !.defined || $_ < $MCID;
           }
           $mcr;
        }
    }
    else {
        fail "unmarked";
    }
}
