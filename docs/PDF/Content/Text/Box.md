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

Methods
-------

style
-----

```raku
        method style() returns PDF::Content::Text::Style
```

Styling delegate for this text box. See[PDF::Content::Text::Style](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Style)

font, font-size, leading, kern, WordSpacing, CharSpacing, HorizScaling, TextRender, TextRise, baseline-shift, space-width, underline-position, underline-thickness, font-height
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

These methods are all handled by the `style` delegate. For example `$tb.font-height` is equivalent to `$tb.style.font-height`.

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

