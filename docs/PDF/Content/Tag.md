[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [Tag](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Tag)

class PDF::Content::Tag
-----------------------

Tagged and marked content

Description
-----------

This class assists in the detection or construction of tagged and marked content in page or xobject form content streams:

Example
-------

```raku
use lib 't';
use PDFTiny;
use PDF::Content::XObject;
use PDF::Content::Tag :ParagraphTags, :IllustrationTags;

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $pdf.core-font: :family<Helvetica>;

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

Methods
-------



See [PDF 32000 Tables 333 - Standard structure types for grouping elements]



See [PDF 32000 Tables 334-337 - Block-level structure elements]



See [PDF 32000 Table 338 - Standard structure types for inline-level structure elements]



These tags are meaningful within content streams, as opposed to the structure-tree

### multi method add-kid

```raku
multi method add-kid(
    PDF::Content::Tag $kid
) returns PDF::Content::Tag
```

Add a child tag

### method take-descendants

```raku
method take-descendants() returns Mu
```

take self and all descendants

### method descendants

```raku
method descendants() returns Seq
```

gather all descendants

