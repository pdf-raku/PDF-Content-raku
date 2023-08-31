#| Simple color construction functions
unit module PDF::Content::Color;

=head2 Synopsis

=begin code :lang<raku>
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
=end code

=head2 Subroutines

use Color;

my Array enum ColorName is export(:ColorName) «
    :Aqua[0, 1, 1]      :Black[0, 0, 0]
    :Blue[0, 0, 1]      :Fuchsia[1, 0, 1]
    :Gray[.5, .5, .5]   :Green[0, .5, 0]
    :Lime[0, 1, 0]      :Maroon[.5, 0, 0]
    :Navy[0, 0, .5]     :Olive[.5, .5, 0]
    :Orange[1, 0.65, 0] :Purple[.5, 0, .5]
    :Red[1, 0, 0]       :Silver[.75, .75, .75]
    :Teal[0, .5, .5]    :White[1, 1, 1]
    :Yellow[1, 1, 0]    :Cyan[0, 1, 1]
    :Magenta[1, 0, 1]   :Registration[1, 1, 1, 1]
   »;

#| build RGB Op
our sub rgb(\r, \g, \b --> Pair) is export(:rgb) {
    :DeviceRGB[r, g, b]
}
#| build CMYK Op
our sub cmyk(\c, \m, \y, \k --> Pair) is export(:cmyk) {
    :DeviceCMYK[c, m, y, k];
}
#| build Gray Op
our sub gray(\g --> Pair) is export(:gray) {
    :DeviceGray[g];
}

#| Coerce a color to an Op
our proto sub color(| --> Pair) is export(:color) {*};
multi sub color(Color $_) { color([.rgb]) }
multi sub color(Numeric $a, *@c) { @c.prepend($a); color(@c); }
multi sub color(List $_) {
    when .max >= 2   {color .map(*/255).list}
    when .elems == 4 {cmyk(|$_)}
    when .elems == 3 {rgb(|$_)}
    when .elems == 1 {gray(.[0])}
}
multi sub color(Str $_) {
    when /^'#'<xdigit>**3$/ { rgb( |@<xdigit>.map({:16(.Str ~ .Str) / 255 })) }
    when /^'#'<xdigit>**6$/ { rgb( |@<xdigit>.map({:16($^a.Str ~ $^b.Str) / 255 })) }
    when /^'%'<xdigit>**4$/ { cmyk( |@<xdigit>.map({:16(.Str ~ .Str) / 255 })) }
    when /^'%'<xdigit>**8$/ { cmyk( |@<xdigit>.map({:16($^a.Str ~ $^b.Str) / 255 })) }
    default { warn "unrecognized color: $_"; gray(1) }
}
multi sub color(Pair $c) { $c }

