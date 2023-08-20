[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [Color](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Color)

module PDF::Content::Color
--------------------------

Simple color construction functions

Synopsis
--------

```raku
use lib 't';
use PDFTiny;
my $page = PDFTiny.new.add-page;
use PDF::Content;
use PDF::Content::Color :color, :ColorName;
my PDF::Content $gfx = $page.gfx;
$gfx.Save;
$gfx.FillColor = color Blue; # named color
$gfx.StrokeColor = color '#fa9'; # RGB mask, 3 digit
$gfx.StrokeColor = color '#ffaa99'; # RGB mask, 6 digit
$gfx.StrokeColor = color [1, .8, .1, .2]; # CMYK color values (0..1)
$gfx.StrokeColor = color [1, .5, .1];     # RGB color values (0..1)
$gfx.StrokeColor = color [255, 127, 25];  # RGB color values (0..255)
$gfx.StrokeColor = color .7; # Shade of gray
use Color;
my Color $red .= new(0xff, 0x0a, 0x0a);
$gfx.StrokeColor = color $red; # Color objects
$gfx.Restore;
```

Subroutines
-----------

### sub rgb

```raku
sub rgb(
    \r,
    \g,
    \b
) returns Pair
```

build RGB Op

### sub cmyk

```raku
sub cmyk(
    \c,
    \m,
    \y,
    \k
) returns Pair
```

build CMYK Op

### sub gray

```raku
sub gray(
    \g
) returns Pair
```

build Gray Op

### sub color

```raku
sub color(
    |
) returns Pair
```

Coerce a color to an Op

