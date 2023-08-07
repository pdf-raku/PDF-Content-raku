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

### multi method height

```raku
multi method height(
    Numeric $pointsize?,
    Bool :$from-baseline,
    Bool :$hanging
) returns Mu
```

compute the overall font-height

