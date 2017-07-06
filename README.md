# PDF::Content

This is a Perl 6 module for basic PDF content creation and rendering, including text, images, fonts and general graphics.

It is centered around implementing a graphics state machine and
provding support for the operators and graphics state variables
as listed in the appendix.

It does just enough to be able to read and edit PDF files.


## See Also

- [PDF::Lite](https://github.com/p6-pdf/PDF-Lite-p6) implements minimal classess for creating and manipulating PDF documents.

- [PDF::Render::Cairo](https://github.com/p6-pdf/PDF-Render-Cairo-p6)  experimental lightweight PDF renderer to Cairo supported formats including PNG and SVG.

- [PDF::Zen](https://github.com/p6-pdf/PDF-Zen-p6) experimental fully
featured PDF Reader.


## Appendix: Graphics Operators and Variables

### Graphic Operators


#### Color Operators

Method | Code | Description
--- | --- | ---
SetStrokeColorSpace(name) | CS | Set the current space to use for stroking operations. This can be a standard name, such as 'DeviceGray', 'DeviceRGB', 'DeviceCMYK', or a name declared in the parent's Resource<ColorSpace> dictionary.
SetStrokeColorSpace(name) | cs | Same but for nonstroking operations.
SetStrokeColor(c1, ..., cn) | SC | Set the colours to use for stroking operations in a device. The number of operands required and their interpretation depends on the current stroking colour space: DeviceGray, CalGray, and Indexed colour spaces, have one operand. DeviceRGB, CalRGB, and Lab colour spaces, three operands. DeviceCMYK has four operands.
SetStrokeColorN(c1, ..., cn [,pattern-name]) | SCN | Same as SetStrokeColor but also supports Pattern, Separation, DeviceN, ICCBased colour spaces and patterns.
SetFillColor(c1, ..., cn) | sc | Same as SetStrokeColor, but for non-stroking operations.
SetFillColorN(c1, ..., cn [,pattern-name]) | scn | Same as SetStrokeColorN, but for non-stroking operations.
SetStrokeGray(level) | G | Set the stroking colour space to DeviceGray and set the gray level to use for stroking operations, between 0.0 (black) and 1.0 (white).
SetFillGray(level) | g | Same as G but used for nonstroking operations.
SetStrokeRGB(r, g, b) | RG | Set the stroking colour space to DeviceRGB and set the colour to use for stroking operations. Each operand shall be a number between 0.0 (minimum intensity) and 1.0 (maximum intensity).
SetFillRGB(r, g, b) | rg | Same as RG but used for nonstroking operations.
SetFillCMYK(c, m, y, k) | K | Set the stroking colour space to DeviceCMYK and set the colour to use for stroking operations. Each operand shall be a number between 0.0 (zero concentration) and 1.0 (maximum concentration). The behaviour of this operator is affected by the OverprintMode graphics state.
SetStrokeRGB(c, m, y, k) | k | Same as K but used for nonstroking operations.

#### Graphics State

Method | Code | Description
--- | --- | ---
Save() | q | Save the current graphics state on the graphics state stack
Restore() | Q | Restore the graphics state by removing the most recently saved state from the stack and making it the current state.
ConcatMatrix(a, b, c, d, e, f) | cm | Modify the current transformation matrix (CTM) by concatenating the specified matrix
SetLineWidth(width) | w | Set the line width in the graphics state
SetLineCap(cap-style) | J | Set the line cap style in the graphics state (see LineCap enum)
SetLineJoin(join-style) | j | Set the line join style in the graphics state (see LineJoin enum)
SetMiterLimit(ratio) | M | Set the miter limit in the graphics state
SetDashPattern(dashArray, dashPhase) | d | Set the line dash pattern in the graphics state
SetRenderingIntent(intent) | ri | Set the colour rendering intent in the graphics state: AbsoluteColorimetric, RelativeColormetric, Saturation, or Perceptual
SetFlatness(flat) | i | Set the flatness tolerance in the graphics state. flatness is a number in the range 0 to 100; 0 specifies the output device’s default flatness tolerance.
SetGraphics(dictName) | gs | Set the specified parameters in the graphics state. dictName is the name of a graphics state parameter dictionary in the ExtGState resource subdictionary

#### Text Operators

Method | Code | Description
--- | --- | ---
BeginText() | BT | Begin a text object, initializing $.TextMatrix, to the identity matrix. Text objects shall not be nested.
EndText() | ET | End a text object, discarding the text matrix.
TextMove(tx, ty) | Td | Move to the start of the next line, offset from the start of the current line by (tx, ty ); where tx and ty are expressed in unscaled text space units.
TextMoveSet(tx, ty) | TD | Move to the start of the next line, offset from the start of the current line by (tx, ty ). Set $.TextLeading to ty.
SetTextMatrix(a, b, c, d, e, f) | Tm | Set $.TextMatrix
TextNextLine| T* | Move to the start of the next line
ShowText(string) | Tj | Show a text string
MoveShowText(string) | ' | Move to the next line and show a text string.
MoveSetShowText(aw, ac, string) | " | Move to the next line and show a text string, after setting $.WordSpacing to  aw and $.CharSpacing to ac
ShowSpacetext(array) |  TJ | Show one or more text strings, allowing individual glyph positioning. Each element of array shall be either a string or a number. If the element is a string, show it. If it is a number, adjust the text position by that amount

#### Path Construction

Method | Code | Description
--- | --- | ---
MoveTo(x, y) | m | Begin a new subpath by moving the current point to coordinates (x, y), omitting any connecting line segment. If the previous path construction operator in the current path was also m, the new m overrides it.
LineTo(x, y) | l | Append a straight line segment from the current point to the point (x, y). The new current point shall be (x, y).
CurveTo(x1, y1, x2, y2, x3, y3) | c | Append a cubic Bézier curve to the current path. The curve shall extend from the current point to the point (x 3 , y 3 ), using (x1 , y1 ) and (x2 , y2 ) as the Bézier control points. The new current point shall be (x3 , y3 ).

#### Path Painting Operators

Method | Code | Description
--- | --- | ---
Stroke() | S | Stroke the path.
CloseStroke() | s | Close and stroke the path. Same as: $.Close; $.Stroke
Fill() | f | Fill the path, using the nonzero winding number rule to determine the region. Any open subpaths are implicitly closed before being filled.
EOFill() | f* | Fill the path, using the even-odd rule to determine the region to fill
FillStroke() | B | Fill and then stroke the path, using the nonzero winding number rule to determine the region to fill.
EOFillStroke() | B* | Fill and then stroke the path, using the even-odd rule to determine the region to fill.
CloseFillStroke() | b | Close, fill, and then stroke the path, using the nonzero winding number rule to determine the region to fill.
CloseEOFillStroke() | b* | Close, fill, and then stroke the path, using the even-odd rule to determine the region to fill.
EndPath() | n | End the path object without filling or stroking it. This operator shall be a path-painting no-op, used primarily for the side effect of changing the current clipping path.

#### Path Clipping

Method | Code | Description
--- | --- | ---
Clip() | W | Modify the current clipping path by intersecting it with the current path, using the nonzero winding number rule to determine which regions lie inside the clipping path.
EOClip() | W* | Modify the current clipping path by intersecting it with the current path, using the even-odd rule to determine which regions lie inside the clipping path.

### Graphics Variables

#### Text Variables

Accessor | Code | Description | Default | Example Setters
-------- | ------ | ----------- | ------- | -------
TextMatrix | Tm | Text transformation matrix | [1,0,0,1,0,0] | .TextMatrix = :scale(1.5) );
CharSpacing | Tc | Character spacing | 0.0 | .CharSpacing = 1.0
WordSpacing | Tw | Word extract spacing | 0.0 | .WordSpacing = 2.5
HorizScaling | Th | Horizontal scaling (percent) | 100 | .HorizScaling = 150
TextLeading | Tl | New line Leading | 0.0 | .TextLeading = 12; 
Font | [Tf, Tfs] | Text font and size | | .font = [ .core-font( :family\<Helvetica> ), 12 ]
TextRender | Tmode | Text rendering mode | 0 | .TextRender = TextMode::Outline::Text
TextRise | Trise | Text rise | 0.0 | .TextRise = 3

#### General Graphics - Common

Accessor | Code | Description | Default | Example Setters
-------- | ------ | ----------- | ------- | -------
CTM |  | The current transformation matrix | [1,0,0,1,0,0] | use PDF::Content::Matrix :scale;<br>.ConcatMatrix: :scale(1.5); 
DashPattern | D |  A description of the dash pattern to be used when paths are stroked | solid | .DashPattern = [[3, 5], 6];
FillAlpha | ca | The constant shape or constant opacity value to be used for other painting operations | 1.0 | .FillAlpha = 0.25
FillColor| | current fill colorspace and color | :DeviceGray[0.0] | .FillColor = :DeviceCMYK[.7,.2,.2,.1]
LineCap  |  LC | A code specifying the shape of the endpoints for any open path that is stroked | 0 (butt) | .LineCap = LineCaps::RoundCaps;
LineJoin | LJ | A code specifying the shape of joints between connected segments of a stroked path | 0 (miter) | .LineJoin = LineJoin::RoundJoin
StrokeAlpha | CA | The constant shape or constant opacity value to be used when paths are stroked | 1.0 | .StrokeAlpha = 0.5;
StrokeColor| | current stroke colorspace and color | :DeviceGray[0.0] | .StrokeColor = :DeviceRGB[.7,.2,.2]


#### General Graphics - Advanced

Accessor | Code | Description | Default
-------- | ------ | ----------- | -------
AlphaSource | AIS | A flag specifying whether the current soft mask and alpha constant parameters shall be interpreted as shape values or opacity values. This flag also governs the interpretation of the SMask entry | false |
BlackGeneration | BG2 | A function that calculates the level of the black colour component to use when converting RGB colours to CMYK
BlendMode | BM | The current blend mode to be used in the transparent imaging model |
Flatness | FT | The precision with which curves shall be rendered on the output device. The value of this parameter gives the maximum error tolerance, measured in output device pixels; smaller numbers give smoother curves at the expense of more computation | 1.0 
Halftone dictionary | HT |  A halftone screen for gray and colour rendering
MiterLimit | ML | number The maximum length of mitered line joins for stroked paths |
OverPrintMode | OPM | A flag specifying whether painting in one set of colorants should cause the corresponding areas of other colorants to be erased or left unchanged | false
OverPrintPaint | OP | A code specifying whether a colour component value of 0 in a DeviceCMYK colour space should erase that component (0) or leave it unchanged (1) when overprinting | 0
OverPrintStroke | OP | " | 0
RenderingIntent | RI | The rendering intent to be used when converting CIE-based colours to device colours | RelativeColorimetric
SmoothnessTolerance | ST | The precision with which colour gradients are to be rendered on the output device. The value of this parameter (0 to 1.0) gives the maximum error tolerance, expressed as a fraction of the range of each colour component; smaller numbers give smoother colour transitions at the expense of more computation and memory use.
SoftMask | SMask | A soft-mask dictionary specifying the mask shape or mask opacity values to be used in the transparent imaging model, or the name: None | None
StrokeAdjust | SA | A flag specifying whether to compensate for possible rasterization effects when stroking a path with a line | false
TransferFunction | TR2 |  A function that adjusts device gray or colour component levels to compensate for nonlinear response in a particular output device
UndercolorRemovalFunction | UCR2 | A function that calculates the reduction in the levels of the cyan, magenta, and yellow colour components to compensate for the amount of black added by black generation

