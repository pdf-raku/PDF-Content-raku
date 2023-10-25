[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: Text
 :: [Box](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Box)

class PDF::Content::Text::Box
-----------------------------

simple plain-text blocks

Synopsis
--------

```raku
use lib 't';
use PDFTiny;
my $page = PDFTiny.new.add-page;
use PDF::Content;
use PDF::Content::Font::CoreFont;
use PDF::Content::Text::Block;
my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my $text = "Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my PDF::Content::Text::Box $text-box .= new( :$text, :$font, :font-size(16) );
my PDF::Content $gfx = $page.gfx;
$gfx.BeginText;
$text-box.render($gfx);
$gfx.EndText;
say $gfx.Str;
```

Description
-----------

Text boxes are used to implement the [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content) `print` and `say` methods. They usually work "behind the scenes". But can be created as objects and then passed to `print` and `say`:

```raku
use PDF::Lite;
use PDF::Content;
use PDF::Content::Text::Box;

my PDF::Lite $pdf .= new;

my $font-size = 16;
my $height = 20;
my $text = "Hello.  Ting, ting-ting.";

my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my PDF::Content::Text::Box $text-box .= new( :$text, :$font, :$font-size, :$height );

say "width:" ~ $text-box.width;
say "height:" ~ $text-box.height;
say "underline-thickness:" ~ $text-box.underline-thickness;
say "underline-position:" ~ $text-box.underline-position;

my $page = $pdf.add-page;

$page.text: {
    .text-position = 10, 20;
    .say: $text-box;
    .text-position = 10, 50;
    .print: $text-box;
}

$pdf.save-as: "test.pdf";
```

Methods
-------

### method text

The text contained in the text box. This is a `rw` accessor. It can also be used to replace the text contained in a text box.

### method width

The constraining width for the text box.

### method height

The constraining height for the text box.

### method indent

The indentation of the first line (points).

### method align

Horizontal alignment `left`, `center`, or `right`.

### method valign

Vertical alignment of mutiple-line text boxes: `top`, `center`, or `bottom`.

See also the :baseline` option for vertical displacememnt of the first line of text.

style
-----

```raku
method style() returns PDF::Content::Text::Style
```

Styling delegate for this text box. See[PDF::Content::Text::Style](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Style)

This method also handles method `font`, `font-size`, `leading`, `kern`, `WordSpacing`, `CharSpacing`, `HorizScaling`, `TextRender`, `TextRise`, `baseline-shift`, `space-width`, `underline-position`, `underline-thickness`, `font-height`. For example `$tb.font-height` is equivalent to `$tb.style.font-height`.

### method content-width

```raku
method content-width() returns Numeric
```

return the actual width of content in the text box

Calculated from the longest line in the text box.

### method content-height

```raku
method content-height() returns Numeric
```

return the actual height of content in the text box

Calculated from the number of lines in the text box.

### method comb

```raku
method comb(
    Str $_
) returns Seq
```

break a text string into word and whitespace fragments

### method clone

```raku
method clone(
    :$text = Code.new,
    |c
) returns PDF::Content::Text::Box
```

clone a text box

### method width

```raku
method width() returns Numeric
```

return displacement width of a text box

### method height

```raku
method height() returns Numeric
```

return displacement height of a text box

### method render

```raku
method render(
    PDF::Content::Ops:D $gfx,
    Bool :$nl,
    Bool :$top,
    Bool :$left,
    Bool :$preserve = Bool::True
) returns List
```

render a text box to a content stream at current or given text position

### method place-images

```raku
method place-images(
    $gfx
) returns Mu
```

flow any xobject images. This needs to be done after rendering and exiting text block

### method Str

```raku
method Str() returns Str
```

return text split into lines

