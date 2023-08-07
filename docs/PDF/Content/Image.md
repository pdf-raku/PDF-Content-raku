[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)

class PDF::Content::Image
-------------------------

loading and manipulation of PDF images

Synopsis
--------

```raku
use PDF::Content::Image;
my PDF::Content::Image $image .= open: "t/images/lightbulb.gif";
say "image has size {$image.width} X {$image.height}";
say $image.data-uri;
# data:image/gif;base64,R0lGODlhEwATAMQA...
```

Description
-----------

This class currently currently supports image formats: PNG, GIF and JPEG.

