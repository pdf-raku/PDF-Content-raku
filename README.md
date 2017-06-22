# PDF::Content

This is a Perl 6 module for basic PDF content creation and rendering, including text, images, fonts and general graphics.

It is centered around implementing a graphics state machine and
provding support for the operators and graphics state variables
as listed in the appendix.

Please see

- [PDF::Lite](https://github.com/p6-pdf/PDF-Lite-p6) implements minimal classess for creating and manipulating PDF documents.

- [PDF::Content::Cairo](https://github.com/p6-pdf/PDF-Content-Cairo-p6)  under construction as a lightweight PDF renderer to Cairo supported formats including PNG and SVG.

- [PDF::Doc](https://github.com/p6-pdf/PDF-Doc-p6) experimental fully
featured PDF Library, based on PDF::Content.

## Graphic Operators

...

## Graphics Variables

### Text

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

### General Graphics - Common

Accessor | Code | Description | Default | Example Setters
-------- | ------ | ----------- | ------- | -------
CTM |  | The current transformation matrix | [1,0,0,1,0,0] | use PDF::Content::Matrix :scale;<br>.ConcatMatrix: :scale(1.5); 
StrokeColor| | current stroke colorspace and color | :DeviceGray[0.0] | .StrokeColor = :DeviceRGB[.7,.2,.2]
FillColor| | current fill colorspace and color | :DeviceGray[0.0] | .FillColor = :DeviceCMYK[.7,.2,.2,.1]
LineCap  |  LC | A code specifying the shape of the endpoints for any open path that is stroked | 0 (butt) | .LineCap = LineCaps::RoundCaps;
LineJoin | LJ | A code specifying the shape of joints between connected segments of a stroked path | 0 (miter) | .LineJoin = LineJoin::RoundJoin
DashPattern | D |  A description of the dash pattern to be used when paths are stroked | solid | .DashPattern = [[3, 5], 6];
StrokeAlpha | CA | The constant shape or constant opacity value to be used when paths are stroked | 1.0 | .StrokeAlpha = 0.5;
FillAlpha | ca | The constant shape or constant opacity value to be used for other painting operations | 1.0 | .FillAlpha = 0.25


### General Graphics - Advanced

Accessor | Code | Description | Default
-------- | ------ | ----------- | -------
MiterLimit | ML | number The maximum length of mitered line joins for stroked paths |
RenderingIntent | RI | The rendering intent to be used when converting CIE-based colours to device colours | RelativeColorimetric
StrokeAdjust | SA | A flag specifying whether to compensate for possible rasterization effects when stroking a path with a line | false
BlendMode | BM | The current blend mode to be used in the transparent imaging model |
SoftMask | SMask | A soft-mask dictionary specifying the mask shape or mask opacity values to be used in the transparent imaging model, or the name: None | None
AlphaSource | AIS | A flag specifying whether the current soft mask and alpha constant parameters shall be interpreted as shape values or opacity values. This flag also governs the interpretation of the SMask entry | false |
OverPrintMode | OPM | A flag specifying whether painting in one set of colorants should cause the corresponding areas of other colorants to be erased or left unchanged | false
OverPrintPaint | OP | A code specifying whether a colour component value of 0 in a DeviceCMYK colour space should erase that component (0) or leave it unchanged (1) when overprinting | 0
OverPrintStroke | OP | " | 0
BlackGeneration | BG2 | A function that calculates the level of the black colour component to use when converting RGB colours to CMYK
UndercolorRemovalFunction | UCR2 | A function that calculates the reduction in the levels of the cyan, magenta, and yellow colour components to compensate for the amount of black added by black generation
TransferFunction | TR2 |  A function that adjusts device gray or colour component levels to compensate for nonlinear response in a particular output device
Halftone dictionary | HT |  A halftone screen for gray and colour rendering
FlatnessTolerance | FT | The precision with which curves shall be rendered on the output device. The value of this parameter gives the maximum error tolerance, measured in output device pixels; smaller numbers give smoother curves at the expense of more computation | 1.0 
SmoothnessTolerance | ST | The precision with which colour gradients are to be rendered on the output device. The value of this parameter (0 to 1.0) gives the maximum error tolerance, expressed as a fraction of the range of each colour component; smaller numbers give smoother colour transitions at the expense of more computation and memory use.
