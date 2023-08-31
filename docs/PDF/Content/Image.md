[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [Image](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Image)

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

This class currently supports image formats: PNG, GIF and JPEG.

head2Methods
============



### multi method load

```raku
multi method load(
    Str $data-uri where { ... }
) returns PDF::Content::Image
```

load an image from a data URI string

### multi method load

```raku
multi method load(
    IO::Path(Any) $io-path
) returns PDF::Content::Image
```

load an image from a path

### multi method load

```raku
multi method load(
    IO::Handle $source
) returns PDF::Content::Image
```

load an image from an IO handle

### method data-uri

```raku
method data-uri() returns PDF::Content::Image::DataURI
```

Get or set the data URI from an image

