# perl6-PDF-Basic

Perl 6 module for basic PDF content creation and editing, including text, images, fonts and general graphics.

It includes `PDF::Basic::Doc` a minimal class for
creating or editing PDF documents, inclduing:
- Basic Text (core fonts only)
- Simple forms and images
- Low-level graphics and content operators
- Basic reuse (Pages and form objects)
```
use v6;
use PDF::Basic::Doc;

my $pdf = PDF::Basic::Doc.new;
my $page = $pdf.add-page;
$page.MediaBox = [0, 0, 595, 842];
my $font = $page.core-font( :family<Helvetica>, :weight<bold>, :style<italic> );
$page.text: -> $_ {
    .text-position = [100, 150];
    .set-font: $font;
    .say: 'Hello, world!';
}

my $info = $pdf.Info = {};
$info.CreationDate = DateTime.now;

$pdf.save-as: "t/example.pdf";
```

#### Text

`.say` and `.print` are simple convenience methods for displaying simple blocks of text with optional line-wrapping, alignment and kerning.

```
use PDF::Basic::Doc;
my $doc = PDF::Basic::Doc.new;
my $page = $doc.add-page;
my $font = $page.core-font( :family<Helvetica> );

$page.text: -> $txt {
    my $para = q:to"--END--";
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua.
    --END--
            
    $txt.set-font($font, :font-size(12));
    $txt.say( $para, :width(200), :height(150) :align<right>, :kern);
}
```

#### Forms and images (`.image` and  `.do` methods):

The `.image` method can be used to load an image and register it as a page resource.
The `.do` method can them be used to render it.

```
use PDF::Basic::Doc;
my $doc = PDF::Basic::Doc.new;
my $page = $doc.add-page;

$page.graphics: -> $gfx {
    my $img = $gfx.load-image("t/images/snoopy-happy-dance.jpg");
    $gfx.do($img, 150, 380, :width(150) );

    # displays the image again, semi-transparently with translation, rotation and scaling

    $gfx.transform( :translate[285, 250]);
    $gfx.transform( :rotate(-10), :scale(1.5) );
    $gfx.set-graphics( :transparency(.5) );
    $gfx.do($img, 300, 380, :width(150) );
}
```

Note: at this stage, only the `JPEG`, `GIF` and `PNG` image formats are supported.

For a full table of `.set-graphics` options, please see PDF::Basic::Ops, ExtGState enumeration.

### Text effects

To display card suits symbols, using the ZapfDingbats core-font. Diamond and hearts colored red:

```
use PDF::Basic::Doc;
my $doc = PDF::Basic::Doc.new;
my $page = $doc.add-page;

$page.graphics: -> $_ {

    $page.text: -> $txt {
	$txt.text-position = [240, 600];
	$txt.set-font( $page.core-font('ZapfDingbats'), 24);
	$txt.SetWordSpacing(16);
	my $nbsp = "\c[NO-BREAK SPACE]";
	$txt.print("♠ ♣$nbsp");
	$txt.SetFillRGB( 1, .3, .3);  # reddish
	$txt.say("♦ ♥");
    }

    # Display outline, slanted text, using the ShowText (`Td`) operator:

    my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );

    $page.text: -> $_ {
	 use PDF::Basic::Ops :TextMode;
	.set-font( $header-font, 12);
	.SetTextRender: TextMode::OutlineText;
	.SetLineWidth: .5;
	.text-transform( :translate[50, 550], :slant(12) );
	.ShowText('Outline Slanted Text @(50,550)');
    }
}

```

Note: at this stage, only the PDF core fonts are supported: Courier, Times, Helvetica, ZapfDingbats and Symbol.

#### Low level graphics, colors and drawing

PDF::Basic::Doc::Contents::Gfx inherits from PDF::Basic, which implements the full range of PDF content operations, plus
utility methods for handling text, images and graphics coordinates:

```
use PDF::Basic::Doc;
my $doc = PDF::Basic::Doc.new;
my $page = $doc.add-page;

# Draw a simple Bézier curve:

# ------------------------
# Alternative 1: Using operator functions (see PDF::Basic)

sub draw-curve1($gfx) {
    $gfx.Save;
    $gfx.MoveTo(175, 720);
    $gfx.LineTo(175, 700);
    $gfx.CurveTo1( 300, 800, 
                   400, 720 );
    $gfx.ClosePath;
    $gfx.Stroke;
    $gfx.Restore;
}

draw-curve1($page.gfx);

# ------------------------
# Alternative 2: draw from content instructions:

sub draw-curve2($gfx) {
    $gfx.ops: q:to"--END--"
        q                     % save
          175 720 m           % move-to
          175 700 l           % line-to
          300 800 400 720 v   % curve-to
          h                   % close
          S                   % stroke
        Q                     % restore
        --END--
}
draw-curve2($doc.add-page.gfx);

# ------------------------
# Alternative 3: draw from raw data

sub draw-curve3($gfx) {
    $gfx.ops: [
         'q',               # save,
         :m[175, 720],      # move-to
         :l[175, 700],      # line-to 
         :v[300, 800,
            400, 720],      # curve-to
         :h[],              # close (:h[] is equivalent to 'h')
         'S',               # stroke
         'Q',               # restore
     ];
}
draw-curve3($doc.add-page.gfx);

```

For a full list of operators, please see PDF::Basic.

### Resources and Reuse

To list all images and forms for each page
```
use PDF::Basic::Doc;
my $doc = PDF::Basic::Doc.open: "t/images.pdf";
for 1 ... $doc.page-count -> $page-no {
    say "page: $page-no";
    my $page = $doc.page: $page-no;
    my %object = $page.resources('XObject');

    # also report on images embedded in the page content
    my $k = "(inline-0)";

    %object{++$k} = $_
        for $page.gfx.inline-images;

    for %object.keys -> $key {
        my $xobject = %object{$key};
        my $subtype = $xobject<Subtype>;
        my $size = $xobject.encoded.codes;
        say "\t$key: $subtype $size bytes"
    }
}

```

Resource types are: ExtGState (graphics state), ColorSpace, Pattern, Shading, XObject (forms and images) and Properties.

Resources of type Pattern and XObject/Image may have further associated resources.

Whole pages or individual resources may be copied from one PDF to another.

The `to-xobject` method can be used to convert a page to an XObject Form to layup one or more input pages on an output page.

```
use PDF::Basic::Doc;
my $doc-with-images = PDF::Basic::Doc.open: "t/images.pdf";
my $doc-with-text = PDF::Basic::Doc.open: "t/example.pdf";

my $new-doc = PDF::Basic::Doc.new;

# add a page; layup imported pages and images
my $page = $new-doc.add-page;

my $xobj-image = $doc-with-images.page(1).images[7];
my $xobj-with-text  = $doc-with-text.page(1).to-xobject;
my $xobj-with-images  = $doc-with-images.page(1).to-xobject;

$page.graphics: -> $_ {
     # scale up the image; use it as a background
    .do($xobj-image, 6, 6, :width(600) );

     # overlay pages; scale these down
    .do($xobj-with-text, 100, 200, :width(200) );
    .do($xobj-with-images, 300, 300, :width(200) );
}

# copy whole pages from a document
for 1 .. $doc-with-text.page-count -> $page-no {
    $new-doc.add-page: $doc-with-text.page($page-no);
}

$new-doc.save-as: "t/reuse.pdf";

```

