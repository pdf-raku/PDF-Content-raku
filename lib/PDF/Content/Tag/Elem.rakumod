use PDF::Content::Tag;

unit class PDF::Content::Tag::Elem
    is PDF::Content::Tag;

use PDF::Content;
use PDF::Content::XObject;

method mark(PDF::Content $gfx, &action, |c) {
    self.add-kid: $gfx.tag(self.name, &action, :mark, |c)
}

method set-bbox(PDF::Content $gfx, @rect) {
    self.attributes<BBox> = $gfx.base-coords(@rect).Array;
}

method do(PDF::Content $gfx, PDF::Content::XObject $xobj, Bool :$import, |c) {
    my @rect = $gfx.do($xobj, |c);

    if $import && $xobj ~~ PDF::Content::XObject['Form'] {
        # import tags from the xobject
        my $owner = $gfx.owner;
        my PDF::Content::Tag @marks = $xobj.gfx.tags.descendants.grep(*.mcid.defined);
        for @marks {
            my $mcr = .clone(:$owner, :content($xobj));
            my $name = $mcr.name;
            my $kid = self.new: :$name;
            $kid.add-kid($mcr);
            self.add-kid: $kid;
        }
    }

    self.set-bbox($gfx, @rect)
        if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';

    @rect;
}

method reference(PDF::Content $gfx, PDF::COS::Dict $object, |c) {
    my $owner = $gfx.owner;
    self.add-kid($object, :$owner);
}
