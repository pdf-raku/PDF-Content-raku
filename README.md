# PDF::Content

This Raku module is a library of roles and classes for basic PDF content creation and rendering, including text, images, basic colors, core fonts, marked content and general graphics.

It is centered around implementing a graphics state machine and provding support for the operators and graphics variables
as listed in the [PDF::API6 Graphics Documentation](https://github.com/pdf-raku/PDF-API6#appendix-i-graphics).

## Key roles and classes:

### `PDF::Content`
implements a PDF graphics state machine for composition, or rendering:
```
use lib 't';
use PDF::Content;
use PDFTiny;
my $parent = PDFTiny.new.add-page;
my PDF::Content $gfx .= new: :$parent;
$gfx.use-font: $gfx.core-font('Courier'); # define /F1 font
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

### `PDF::Content::Image`
handles the loading of some common image formats

It currently supports: PNG, GIF and JPEG.

```
use PDF::Content::XObject;
my PDF::Content::XObject $image .= open: "t/images/lightbulb.gif";
say "image has size {$image.width} X {$image.height}";
say $image.data-uri;
# data:image/gif;base64,R0lGODlhEwATAMQA...
```

### `PDF::Content::Font::CoreFont`
provides simple support for core fonts

```
use PDF::Content::Font::CoreFont;
my PDF::Content::Font::CoreFont $font .= load-font( :family<Times-Roman>, :weight<bold> );
say $font.encode("¶Hi");
say $font.stringwidth("RVX"); # 2166
say $font.stringwidth("RVX", :kern); # 2111
```

### `PDF::Content::Text::Block`
a utility class for creating and outputting simple text lines and paragraphs:

```
use lib 't';
use PDFTiny;
my $page = PDFTiny.new.add-page;
use PDF::Content;
use PDF::Content::Font::CoreFont;
use PDF::Content::Text::Block;
my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my $text = "Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my PDF::Content::Text::Block $text-block .= new( :$text, :$font, :font-size(16) );
my PDF::Content $gfx = $page.gfx;
$gfx.BeginText;
$text-block.render($gfx);
$gfx.EndText;
say $gfx.Str;
```

### `PDF::Content::Color`

Simple Color construction functions:

```
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

## `PDF::Content::Tag`

This class assists in the detection or construction of marked content
in page or xobject form content streams:

```
use lib 't';
use PDFTiny;
use PDF::Content::XObject;
use PDF::Content::Tag :ParagraphTags, :IllustrationTags;

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;

    $tag = $gfx.mark: Header1, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    say $tag.name.Str; # 'H1'
    say $tag.mcid;     # marked content id of 0

    $tag = $gfx.mark: Paragraph, {
        .say('Paragraph that contains a figure', :position[50, 100], :font($body-font), :font-size(12));

        # nested tag. Note: marks cannot be nested, but tags can
        .tag: Figure, {
            my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
            .do: $img, :position[50,70];
        }

    }

    say $tag.name.Str;         # 'P'
    say $tag.mcid;             # marked content id of 1
    say $tag.kids[0].name.Str; # 'Figure'
}

say $page.gfx.tags.gist; # '<H1 MCID="0"/><P MCID="1"><Figure/></P>';

```

## See Also

- [PDF::Font::Loader](https://github.com/pdf-raku/PDF-Font-Loader-raku) provides the ability to load and embed Type-1 and True-Type fonts.

- [PDF::Lite](https://github.com/pdf-raku/PDF-Lite-raku) minimal creation and manipulation of PDF documents. Built directly from PDF and this module.

- [PDF::API6](https://github.com/pdf-raku/PDF-API6) PDF manipulation library. Uses this module. Adds handling of outlines, options annotations, separations and device-n colors

- [PDF::Tags](https://github.com/pdf-raku/PDF-Tags-raku) DOM-like creation and reading of tagged PDF structure (under construction)
