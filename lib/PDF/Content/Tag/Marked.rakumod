use PDF::Content::Tag;

unit class PDF::Content::Tag::Marked
    is PDF::Content::Tag;

use PDF::COS;

my subset PageLike of Hash where .<Type> ~~ 'Page';
my subset XObjectFormLike of Hash where .<Subtype> ~~ 'Form';
my subset TagOwner where PageLike|XObjectFormLike;

has TagOwner $.owner is required;
has UInt $.start is rw;
has UInt $.end is rw;
has UInt $.mcid is rw; # marked content identifer

method build-struct-elem(:%nums) {
    with $!mcid -> $MCID {
        PDF::COS.coerce: %(
            :Type( :name<MCR> ),
            :Pg($!owner),
            :$MCID
        );
    }
    else {
       Mu; # nested tag
    }
}
