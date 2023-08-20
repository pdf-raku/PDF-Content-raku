[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [Font](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Font)
 :: [CoreFont](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Font/CoreFont)

class PDF::Content::Font::CoreFont
----------------------------------

Basic PDF core font support

Synopsis
--------

```raku
use PDF::Content::Font::CoreFont;
my PDF::Content::Font::CoreFont $font .= load-font( :family<Times-Roman>, :weight<bold> );
say $font.encode("¶Hi");
say $font.stringwidth("RVX"); # 2166
say $font.stringwidth("RVX", :kern); # 2111
```

Methods
-------

### method core-font-name

```raku
method core-font-name(
    Str:D $family,
    Str :$weight,
    Str :$style
) returns Str
```

get a core font name for the given family, weight and style

### multi method height

```raku
multi method height(
    Numeric $pointsize = 1000,
    Bool :$ex where { ... }
) returns Numeric
```

get the height of 'X' for the font

### multi method height

```raku
multi method height(
    Numeric $pointsize = 1000,
    Bool :$from-baseline,
    Bool :$hanging
) returns Numeric
```

compute the overall font-height

### method stringwidth

```raku
method stringwidth(
    Str $str,
    $pointsize = 0,
    Bool :$kern = Bool::False
) returns Numeric
```

compute the width of a string

### method encoding

```raku
method encoding() returns Str
```

Core font base encoding: WinAsni, MacRoman or MacExpert

### method to-dict

```raku
method to-dict() returns PDF::COS::Dict
```

produce a PDF Font dictionary for this core font

### method font-name

```raku
method font-name() returns Str
```

return the font name

### method underline-position

```raku
method underline-position() returns Numeric
```

return the underline position for the font

### method underline-thickness

```raku
method underline-thickness() returns Numeric
```

return the underline thickness for the font

### method type

```raku
method type() returns Str
```

PDF Font type (always 'Type1' for core fonts)

### method is-embedded

```raku
method is-embedded() returns Bool
```

whether font is embedded (always False for core fonts)

### method is-subset

```raku
method is-subset() returns Bool
```

whether font is subset (always False for core fonts)

### method is-core-font

```raku
method is-core-font() returns Bool
```

whether font is a core font (always True for core fonts)

### method cb-finish

```raku
method cb-finish() returns PDF::COS::Dict
```

finish a PDF rendered font

