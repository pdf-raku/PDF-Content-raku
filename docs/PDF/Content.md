[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)

class PDF::Content
------------------

PDF Content construction and manipulation

Description
-----------

implements a PDF graphics state machine for composition, or rendering:

Synposis
--------

```raku
use lib 't';
use PDF::Content;
use PDF::Content::Canvas;
use PDFTiny;
my PDFTiny $pdf .= new;
my PDF::Content::Canvas $canvas = $pdf.add-page;
my PDF::Content $gfx .= new: :$canvas;
$gfx.use-font: $pdf.core-font('Courier'); # define /F1 font
$gfx.BeginText;
$gfx.Font = 'F1', 16;
$gfx.TextMove(10, 20);
$gfx.ShowText('Hello World');
$gfx.EndText;
say $gfx.Str;
# BT
#  /F1 16 Tf
#  10 20 Td
#  (Hello World) Tj
# ET
```

### method inline-images

```raku
method inline-images() returns Array
```

extract any inline images from the content stream. returns an array of XObject Images

### multi method do

```raku
multi method do(
    PDF::Content::XObject $obj,
    List :$position where { ... } = Code.new,
    Str :$align is copy where { ... } = "left",
    Str :$valign is copy where { ... } = "bottom",
    Numeric :$width is copy,
    Numeric :$height is copy,
    Bool :$inline = Bool::False
) returns Mu
```

place an image, or form object

### multi method print

```raku
multi method print(
    Str $text,
    *%opt
) returns Mu
```

output text leave the text position at the end of the current line

### method text-block

```raku
method text-block(
    $font = Code.new,
    *%opt
) returns Mu
```

deprecated in favour of text-box()

### method say

```raku
method say(
    $text = "",
    *%opt
) returns Mu
```

output text; move the text position down one line

### multi method set-font

```raku
multi method set-font(
    Hash $font,
    Numeric $size = 16
) returns Mu
```

thin wrapper to $.op(SetFont, ...)

