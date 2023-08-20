[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: [Ops](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Ops)

class PDF::Content::Ops
-----------------------

A graphics machine for building and interpeting PDF Content operator streams

Description
-----------

The PDF::Content::Ops role implements methods and mnemonics for the full operator table, as defined in specification [PDF 1.7 Appendix A]:

<table class="pod-table">
<tbody>
<tr> <td>* Operator *</td> <td>*Mnemonic*</td> <td>*Operands*</td> <td>*Description*</td> </tr> <tr> <td>b</td> <td>CloseFillStroke</td> <td>—</td> <td>Close, fill, and stroke path using nonzero winding number rule</td> </tr> <tr> <td>B</td> <td>FillStroke</td> <td>—</td> <td>Fill and stroke path using nonzero winding number rule</td> </tr> <tr> <td>b*</td> <td>CloseEOFillStroke</td> <td>—</td> <td>Close, fill, and stroke path using even-odd rule</td> </tr> <tr> <td>B*</td> <td>EOFillStroke</td> <td>—</td> <td>Fill and stroke path using even-odd rule</td> </tr> <tr> <td>BDC</td> <td>BeginMarkedContentDict</td> <td>tag properties</td> <td>(PDF 1.2) Begin marked-content sequence with property list</td> </tr> <tr> <td>BI</td> <td>BeginImage</td> <td>—</td> <td>Begin inline image object</td> </tr> <tr> <td>BMC</td> <td>BeginMarkedContent</td> <td>tag</td> <td>(PDF 1.2) Begin marked-content sequence</td> </tr> <tr> <td>BT</td> <td>BeginText</td> <td>—</td> <td>Begin text object</td> </tr> <tr> <td>BX</td> <td>BeginExtended</td> <td>—</td> <td>(PDF 1.1) Begin compatibility section</td> </tr> <tr> <td>c</td> <td>CurveTo</td> <td>x1 y1 x2 y2 x3 y3</td> <td>Append curved segment to path (two control points)</td> </tr> <tr> <td>cm</td> <td>ConcatMatrix</td> <td>a b c d e f</td> <td>Concatenate matrix to current transformation matrix</td> </tr> <tr> <td>CS</td> <td>SetStrokeColorSpace</td> <td>name</td> <td>(PDF 1.1) Set color space for stroking operations</td> </tr> <tr> <td>cs</td> <td>SetFillColorSpace</td> <td>name</td> <td>(PDF 1.1) Set color space for nonstroking operations</td> </tr> <tr> <td>d</td> <td>SetDashPattern</td> <td>dashArray dashPhase</td> <td>Set line dash pattern</td> </tr> <tr> <td>d0</td> <td>SetCharWidth</td> <td>wx wy</td> <td>Set glyph width in Type 3 font</td> </tr> <tr> <td>d1</td> <td>SetCharWidthBBox</td> <td>wx wy llx lly urx ury</td> <td>Set glyph width and bounding box in Type 3 font</td> </tr> <tr> <td>Do</td> <td>XObject</td> <td>name</td> <td>Invoke named XObject</td> </tr> <tr> <td>DP</td> <td>MarkPointDict</td> <td>tag properties</td> <td>(PDF 1.2) Define marked-content point with property list</td> </tr> <tr> <td>EI</td> <td>EndImage</td> <td>—</td> <td>End inline image object</td> </tr> <tr> <td>EMC</td> <td>EndMarkedContent</td> <td>—</td> <td>(PDF 1.2) End marked-content sequence</td> </tr> <tr> <td>ET</td> <td>EndText</td> <td>—</td> <td>End text object</td> </tr> <tr> <td>EX</td> <td>EndExtended</td> <td>—</td> <td>(PDF 1.1) End compatibility section</td> </tr> <tr> <td>f</td> <td>Fill</td> <td>—</td> <td>Fill path using nonzero winding number rule</td> </tr> <tr> <td>F</td> <td>FillObsolete</td> <td>—</td> <td>Fill path using nonzero winding number rule (obsolete)</td> </tr> <tr> <td>f*</td> <td>EOFill</td> <td>—</td> <td>Fill path using even-odd rule</td> </tr> <tr> <td>G</td> <td>SetStrokeGray</td> <td>gray</td> <td>Set gray level for stroking operations</td> </tr> <tr> <td>g</td> <td>SetFillGray</td> <td>gray</td> <td>Set gray level for nonstroking operations</td> </tr> <tr> <td>gs</td> <td>SetGraphicsState</td> <td>dictName</td> <td>(PDF 1.2) Set parameters from graphics state parameter dictionary</td> </tr> <tr> <td>h</td> <td>ClosePath</td> <td>—</td> <td>Close subpath</td> </tr> <tr> <td>i</td> <td>SetFlatness</td> <td>flatness</td> <td>Set flatness tolerance</td> </tr> <tr> <td>ID</td> <td>ImageData</td> <td>—</td> <td>Begin inline image data</td> </tr> <tr> <td>j</td> <td>SetLineJoin</td> <td>lineJoin| Set line join style</td> <td></td> </tr> <tr> <td>J</td> <td>SetLineCap</td> <td>lineCap</td> <td>Set line cap style</td> </tr> <tr> <td>K</td> <td>SetStrokeCMYK</td> <td>c m y k</td> <td>Set CMYK color for stroking operations</td> </tr> <tr> <td>k</td> <td>SetFillCMYK</td> <td>c m y k</td> <td>Set CMYK color for nonstroking operations</td> </tr> <tr> <td>l</td> <td>LineTo</td> <td>x y</td> <td>Append straight line segment to path</td> </tr> <tr> <td>m</td> <td>MoveTo</td> <td>x y</td> <td>Begin new subpath</td> </tr> <tr> <td>M</td> <td>SetMiterLimit</td> <td>miterLimit</td> <td>Set miter limit</td> </tr> <tr> <td>MP</td> <td>MarkPoint</td> <td>tag</td> <td>(PDF 1.2) Define marked-content point</td> </tr> <tr> <td>n</td> <td>EndPath</td> <td>—</td> <td>End path without filling or stroking</td> </tr> <tr> <td>q</td> <td>Save</td> <td>—</td> <td>Save graphics state</td> </tr> <tr> <td>Q</td> <td>Restore</td> <td>—</td> <td>Restore graphics state</td> </tr> <tr> <td>re</td> <td>Rectangle</td> <td>x y width height</td> <td>Append rectangle to path</td> </tr> <tr> <td>RG</td> <td>SetStrokeRGB</td> <td>r g b</td> <td>Set RGB color for stroking operations</td> </tr> <tr> <td>rg</td> <td>SetFillRGB</td> <td>r g b</td> <td>Set RGB color for nonstroking operations</td> </tr> <tr> <td>ri</td> <td>SetRenderingIntent</td> <td>intent</td> <td>Set color rendering intent</td> </tr> <tr> <td>s</td> <td>CloseStroke</td> <td>—</td> <td>Close and stroke path</td> </tr> <tr> <td>S</td> <td>Stroke</td> <td>—</td> <td>Stroke path</td> </tr> <tr> <td>SC</td> <td>SetStrokeColor</td> <td>c1 … cn</td> <td>(PDF 1.1) Set color for stroking operations</td> </tr> <tr> <td>sc</td> <td>SetFillColor</td> <td>c1 … cn</td> <td>(PDF 1.1) Set color for nonstroking operations</td> </tr> <tr> <td>SCN</td> <td>SetStrokeColorN</td> <td>c1 … cn [name]</td> <td>(PDF 1.2) Set color for stroking operations (ICCBased and special color spaces)</td> </tr> <tr> <td>scn</td> <td>SetFillColorN</td> <td>c1 … cn [name]</td> <td>(PDF 1.2) Set color for nonstroking operations (ICCBased and special color spaces)</td> </tr> <tr> <td>sh</td> <td>ShFill</td> <td>name</td> <td>(PDF 1.3) Paint area defined by shading pattern</td> </tr> <tr> <td>T*</td> <td>TextNextLine</td> <td>—</td> <td>Move to start of next text line</td> </tr> <tr> <td>Tc</td> <td>SetCharSpacing| charSpace</td> <td>Set character spacing</td> <td></td> </tr> <tr> <td>Td</td> <td>TextMove</td> <td>tx ty</td> <td>Move text position</td> </tr> <tr> <td>TD</td> <td>TextMoveSet</td> <td>tx ty</td> <td>Move text position and set leading</td> </tr> <tr> <td>Tf</td> <td>SetFont</td> <td>font size</td> <td>Set text font and size</td> </tr> <tr> <td>Tj</td> <td>ShowText</td> <td>string</td> <td>Show text</td> </tr> <tr> <td>TJ</td> <td>ShowSpaceText</td> <td>array</td> <td>Show text, allowing individual glyph positioning</td> </tr> <tr> <td>TL</td> <td>SetTextLeading</td> <td>leading</td> <td>Set text leading</td> </tr> <tr> <td>Tm</td> <td>SetTextMatrix</td> <td>a b c d e f</td> <td>Set text matrix and text line matrix</td> </tr> <tr> <td>Tr</td> <td>SetTextRender</td> <td>render</td> <td>Set text rendering mode</td> </tr> <tr> <td>Ts</td> <td>SetTextRise</td> <td>rise</td> <td>Set text rise</td> </tr> <tr> <td>Tw</td> <td>SetWordSpacing</td> <td>wordSpace</td> <td>Set word spacing</td> </tr> <tr> <td>Tz</td> <td>SetHorizScaling</td> <td>scale</td> <td>Set horizontal text scaling</td> </tr> <tr> <td>v</td> <td>CurveToInitial</td> <td>x2 y2 x3 y3</td> <td>Append curved segment to path (initial point replicated)</td> </tr> <tr> <td>w</td> <td>SetLineWidth</td> <td>lineWidth</td> <td>Set line width</td> </tr> <tr> <td>W</td> <td>Clip</td> <td>—</td> <td>Set clipping path using nonzero winding number rule</td> </tr> <tr> <td>W*</td> <td>EOClip</td> <td>—</td> <td>Set clipping path using even-odd rule</td> </tr> <tr> <td>y</td> <td>CurveToFinal</td> <td>x1 y1 x3 y3</td> <td>Append curved segment to path (final point replicated)</td> </tr> <tr> <td>&#39;</td> <td>MoveShowText</td> <td>string</td> <td>Move to next line and show text</td> </tr> <tr> <td>&quot;</td> <td>MoveSetShowText</td> <td>aw ac string</td> <td>Set word and character spacing, move to next line, and show text</td> </tr>
</tbody>
</table>

head
====

Methods

### method font-face

```raku
method font-face() returns PDF::COS::Dict
```

returns the current graphics font dictionary resource

### method font-size

```raku
method font-size() returns Numeric
```

returns the current graphics font size

### method tags

```raku
method tags() returns PDF::Content::Tag::NodeSet
```

returns the current tags status

### multi method gsaves

```raku
multi method gsaves(
    :$delta! where { ... }
) returns Array
```

return graphics gsave stack, including changed variables only

### multi method gsaves

```raku
multi method gsaves() returns Array
```

return graphics gsave stack, including all graphics variables

### multi method graphics-state

```raku
multi method graphics-state(
    :$delta!
) returns Hash
```

return locally updated graphics state variables

### multi method graphics-state

```raku
multi method graphics-state() returns Mu
```

return all current graphics state variables

### method current-point

```raku
method current-point() returns PDF::Content::Ops::Vector
```

return current point

This method is only valid in a path context

### multi method op

```raku
multi method op(
    Pair $_ where { ... }
) returns Mu
```

process operator quarantined by PDF::Grammar::Content as either an unknown operator or having an incorrect argument list

### multi method op

```raku
multi method op(
    *@args is copy
) returns Mu
```

Process a parsed graphics operation

### multi method ops

```raku
multi method ops(
    Str $ops
) returns Array
```

Parse and process graphics operations

### multi method ops

```raku
multi method ops(
    List $ops?
) returns Array
```

Parse and process a list of graphics operations

### method add-comment

```raku
method add-comment(
    Str $_
) returns Mu
```

Add a comment to the content stream

### method parse

```raku
method parse(
    Str $content
) returns Mu
```

parse, but don't process PDF content operators

### method finish

```raku
method finish() returns Mu
```

Finish a content stream

### has Str $!content-cache

serialize content into a string. indent blocks for readability

### method content-dump

```raku
method content-dump() returns Seq
```

serialized current content as a sequence of strings - for debugging/testing

### method FALLBACK

```raku
method FALLBACK(
    $method,
    |c
) returns Mu
```

Treat operator mnemonics as methods

