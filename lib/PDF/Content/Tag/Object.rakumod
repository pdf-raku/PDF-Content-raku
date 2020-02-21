use PDF::Content::Tag;

unit class PDF::Content::Tag::Object
    is PDF::Content::Tag;

has $.owner is required;
has Hash $.object is required; # object reference

my subset PageLike of Hash where .<Type> ~~ 'Page';

method build-struct-elem(:%nums) {
    given $!object -> $Obj {
        my $elem = PDF::COS.coerce: %(
            :Type( :name<OBJR> ),
            :$Obj
        );
        $elem<Pg> = :Pg($!owner)
            if $!owner ~~ PageLike;

        $elem;
    }
}
