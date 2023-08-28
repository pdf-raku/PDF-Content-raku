[[Raku PDF Project]](https://pdf-raku.github.io)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku)

[![Actions Status](https://github.com/pdf-raku/PDF-Content-raku/workflows/test/badge.svg)](https://github.com/pdf-raku/PDF-Content-raku/actions)

# PDF::Content

This Raku module is a library of roles, modules and classes for basic PDF content creation and rendering, including text, images, basic colors, core fonts, marked content and general graphics.

It is centered around implementing a graphics state machine and provding support for the operators and graphics variables
as listed in the [PDF::API6 Graphics Documentation](https://pdf-raku.github.io/PDF-API6#appendix-i-graphics).

## Key classes and modules:

- [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content) manages content stream graphics and related resources

- [PDF::Content::Canvas](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Canvas) manages a canvas that contains a content stream

- [PDF::Content::Ops](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Ops) implements a content stream as a graphics state machine

- [PDF::Content::Image](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Image) loading and manipulation of PDF images

- [PDF::Content::Font::CoreFont](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Font/CoreFont) provides simple support for core fonts

- [PDF::Content::Text::Box](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Box) a utility class for creating boxed text content for output by `print()` or `say()`

- [PDF::Content::Text::Style](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Style) text styling class for text boxes.

- [PDF::Content::Color](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Color) A module of color construction functions

- [PDF::Content::Tag](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Tag) Tagged content detection and construction

- [PDF::Content::PageTree](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/PageTree) PDF Page-tree related methods

## See Also

- [PDF::Font::Loader](https://pdf-raku.github.io/PDF-Font-Loader-raku) provides the ability to load and embed Type-1 and True-Type fonts.

- [PDF::Lite](https://pdf-raku.github.io/PDF-Lite-raku) minimal creation and manipulation of PDF documents. Built directly from PDF and this module.

- [PDF::API6](https://pdf-raku.github.io/PDF-API6) PDF manipulation library. Uses this module. Adds handling of outlines, options annotations, separations and device-n colors

- [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku) DOM-like creation and reading of tagged PDF structure (under construction)
