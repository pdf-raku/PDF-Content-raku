use PDF::Content::Graphics;
use PDF::Content::Resourced;

#| A graphical content container such as a page, xobject form, or pattern
role PDF::Content::Canvas
    does PDF::Content::Graphics
    does PDF::Content::Resourced {

    method canvas(&code) is DEPRECATED<html-canvas> { self.html-canvas(&code) }
    method html-canvas(&code) { self.gfx.html-canvas( &code ) }

}
