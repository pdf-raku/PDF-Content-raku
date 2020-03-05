use PDF::Content::Tag;

unit class PDF::Content::Tag::Elem
    is PDF::Content::Tag;

use PDF::Content;
use PDF::Content::XObject;

has $.owner;

method mark(PDF::Content $gfx, &action, |c) {
    self.add-kid: $gfx.tag(self.name, &action, :mark, |c)
}

method set-bbox(PDF::Content $gfx, @rect) {
    self.attributes<BBox> = $gfx.base-coords(@rect).Array;
}

method do(PDF::Content $gfx, PDF::Content::XObject $xobj, |c) {
    my @rect = $gfx.do($xobj, |c);

    if $xobj ~~ PDF::Content::XObject['Form'] {
        my $owner = $gfx.owner;
        my PDF::Content::Tag @marks = $xobj.gfx.tags.children.grep(*.mcid.defined);
        for @marks {
            self.add-kid: .clone(:$owner, :content($xobj));
        }
    }

    self.set-bbox($gfx, @rect)
        if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';

    @rect;
}

