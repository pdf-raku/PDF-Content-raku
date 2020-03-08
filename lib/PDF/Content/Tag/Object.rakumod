use PDF::Content::Tag;

unit class PDF::Content::Tag::Object
    is PDF::Content::Tag;

use PDF::COS::Dict;

my subset PageLike of Hash where .<Type> ~~ 'Page';
has PageLike $.owner is required;
has PDF::COS::Dict $.object is required; # referenced object

method build-struct-elem(:%parents) {
    given $!object -> $Obj {
        my $elem = PDF::COS.coerce: %(
            :Type( :name<OBJR> ),
            :$Obj,
            :Pg($!owner);
        );

        $elem<Pg> = $_ given $!owner;
        %parents{$Obj} = $elem;

        $elem;
    }
}
