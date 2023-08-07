[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [Canvas](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Canvas)



A graphical content container such as a page, xobject form, or pattern
this role is applied to PDF::Content::Type::Page, PDF::Content::Type::Pattern and PDF::Content::Type::XObject::Form

### method gfx

```raku
method gfx(
    |c
) returns PDF::Content
```

appended graphics return appended PDF content stream

### method has-pre-gfx

```raku
method has-pre-gfx() returns Mu
```

prepended graphics

### method pre-gfx

```raku
method pre-gfx() returns PDF::Content
```

return prepended graphics

### method next-mcid

```raku
method next-mcid() returns UInt:D
```

Allocate the next MCID (Marked Content Identifier)

### method tidy

```raku
method tidy(
    @ops
) returns Mu
```

Fix nesting issues that aren't illegal, but could cause problems: - append any missing 'Q' (Restore) operators at end of stream - wrap with 'q' (Save) and 'Q' (Restore) operators, if there are any top-level graphics, which may affect the state.

### method contents

```raku
method contents() returns Str
```

return contents

### method contents-parse

```raku
method contents-parse() returns Mu
```

reparse contents

### method render

```raku
method render(
    Bool :$tidy = Bool::True,
    |c
) returns Mu
```

render graphics

### method finish

```raku
method finish() returns Mu
```

finish for serialization purposes

### method xobject-form

```raku
method xobject-form(
    :$group = Bool::True,
    *%dict
) returns Mu
```

create a child XObject Form

### method tiling-pattern

```raku
method tiling-pattern(
    List :$BBox!,
    Numeric :$XStep = Code.new,
    Numeric :$YStep = Code.new,
    Int :$PaintType = 1,
    Int :$TilingType = 1,
    Hash :$Resources = Code.new,
    *%dict
) returns Mu
```

create a new Type 1 (Tiling) Pattern

### method save-as-image

```raku
method save-as-image(
    Str $outfile where { ... },
    |c
) returns Mu
```

draft rendering via Cairo (experimental)

The [PDF::To::Cairo](https://pdf-raku.github.io/PDF-Class-raku) module must be installed to use this method

