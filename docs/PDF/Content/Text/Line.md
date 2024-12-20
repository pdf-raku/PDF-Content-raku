[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: Text
 :: [Line](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Line)

class PDF::Content::Text::Line
------------------------------

A single line of a text box

Description
-----------

This class represents a single line of output in a [PDF::Content::Text::Box](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Box).

Methods
-------

### method text

Return the input text for the line.

### method decoded

Return a list of input text atoms

### method encoded

An list of font encodings

### method height

Height of the line.

### method word-gap

Spacing between words.

### method indent

indentation offset.

### method align

Alignment offset.

### method content-width

Return the width of rendered content.

