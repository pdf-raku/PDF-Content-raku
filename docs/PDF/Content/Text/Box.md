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

### method comb

```raku
method comb(
    Str $_
) returns Mu
```

break a text string into word and whitespace fragments

### method clone

```raku
method clone(
    :$text = Code.new,
    |c
) returns Mu
```

clone a text box

### method word-gap

```raku
method word-gap() returns Numeric
```

calculates actual spacing between words

### method width

```raku
method width() returns Mu
```

return displacement width of a text box

### method height

```raku
method height() returns Mu
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
) returns Mu
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
method Str() returns Mu
```

return text split into lines

