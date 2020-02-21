use PDF::Content::Tag;

unit class PDF::Content::Tag::Elem
    is PDF::Content::Tag;

use PDF::Content;
use PDF::Content::Graphics;

has $.owner;

multi method graphics(PDF::Content::Graphics $content, &action) {
    self.graphics($content.gfx, &action);
}

multi method graphics(PDF::Content $gfx, &action) {
    fail "starting page with partially constructed marked content: {$gfx.open-tags.map(*.gist).join}"
        if $gfx.open-tags;

    my $rv := $gfx.graphics(&action);

    fail "graphics finished with partially constructed marked content: {$gfx.open-tags.map(*.gist).join}"
        if $gfx.open-tags;

    for $gfx.tags.tags -> $tag {
        unless $tag.parent {
            $gfx.set-mcid($tag);
            self.add-kid($tag, :owner($gfx));
        }
    }

    $rv;
}
