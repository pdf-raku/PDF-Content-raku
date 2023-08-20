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

Methods
-------

### method graphics

```raku
method graphics(
    &meth
) returns Mu
```

Add a graphics block

### method text

```raku
method text(
    &meth
) returns Mu
```

Add a text block

### method mark

```raku
method mark(
    Str $t,
    &meth,
    |c
) returns PDF::Content::Tag
```

Add a marked content block

### multi method tag

```raku
multi method tag(
    Str $tag,
    Bool :$mark,
    *%props
) returns PDF::Content::Tag
```

Add an empty content tag, optionally marked

### multi method tag

```raku
multi method tag(
    Str $tag,
    &meth,
    Bool :$mark,
    *%props
) returns PDF::Content::Tag
```

Add tagged content, optionally marked

### method load-image

```raku
method load-image(
    $spec
) returns PDF::Content::XObject
```

Open an image from a file-spec or data-uri

### method inline-images

```raku
method inline-images() returns Array[PDF::Content::XObject]
```

extract any inline images from the content stream. returns an array of XObject Images

### method transform

```raku
method transform(
    |c
) returns Mu
```

perform a series of graphics transforms

### method text-transform

```raku
method text-transform(
    |c
) returns Mu
```

perform a series of text transforms

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
) returns List
```

place an image, or form object

### method use-pattern

```raku
method use-pattern(
    Hash $pat where { ... }
) returns Mu
```

ensure pattern is declared as a resource

### multi method paint

```raku
multi method paint(
    Bool :$fill,
    Bool :$even-odd,
    Bool :$close,
    Bool :$stroke
) returns Mu
```

fill and stroke the current path

### multi method paint

```raku
multi method paint(
    &meth,
    *%o
) returns Mu
```

build a path, then fill and stroke it

### multi sub make-font

```raku
multi sub make-font(
    PDF::COS::Dict:D(Any):D $dict where { ... }
) returns PDF::COS::Dict
```

associate a font dictionary with a font object

### method text-box

```raku
method text-box(
    Any:D :$font where { ... } = Code.new,
    Numeric:D :$font-size = Code.new,
    *%opt
) returns PDF::Content::Text::Box
```

create a text box object for use in graphics .print() or .say() methods

### multi method print

```raku
multi method print(
    Str $text,
    *%opt
) returns List
```

output text leave the text position at the end of the current line

### method text-position

```raku
method text-position() returns PDF::Content::Vector
```

get or set the current text position

### multi method print

```raku
multi method print(
    PDF::Content::Text::Box $text-box,
    List :$position where { ... },
    Bool :$nl = Bool::False,
    Bool :$preserve = Bool::True
) returns List
```

print a text block object

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

### method font

```raku
method font() returns Array
```

Get or set the current font as ($font, $font-size)

### multi method print

```raku
multi method print(
    Str $text,
    :$font = Code.new,
    |c
) returns List
```

print text to the content stream

### method html-canvas

```raku
method html-canvas(
    &mark-up,
    |c
) returns Mu
```

add graphics using HTML Canvas 2D API

The HTML::Canvas::To::PDF Raku module must be installed to use this method

### method draw

```raku
method draw(
    $html-canvas,
    :$renderer,
    |c
) returns Mu
```

render an HTML canvas

### method base-coords

```raku
method base-coords(
    *@coords where { ... },
    :$user = Bool::True,
    :$text = Code.new
) returns Array
```

map transformed user coordinates to untransformed (default) coordinates

### method user-coords

```raku
method user-coords(
    *@coords where { ... },
    :$user = Bool::True,
    :$text = Code.new
) returns Array
```

inverse of base-coords

