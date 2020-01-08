use PDF::Content::Tag;

unit class PDF::Content::Tag::Elem
    is PDF::Content::Tag;

use PDF::Content;
use PDF::Content::Page;

my subset PageGraphics of PDF::Content where .parent ~~ PDF::Content::Page;

multi method graphics(PDF::Content::Page $page, &action) {
    self.graphics($page.gfx, &action);
}

multi method graphics(PageGraphics $gfx, &action) {
    fail "starting page with partially constructed marked content: {$gfx.open-tags.map(*.gist).join}"
        if $gfx.open-tags;

    my $rv := $gfx.graphics(&action);

    fail "page finished with partially constructed marked content: {$gfx.open-tags.map(*.gist).join}"
        if $gfx.open-tags;

    given $gfx.tags {
        self.add-kid(.shift)
            while $_;
    }

    $rv;
}
