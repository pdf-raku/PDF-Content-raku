#| simple plain-text blocks
unit class PDF::Content::Text::Box;

=head2 Synopsis

=begin code :lang<raku>
use lib 't';
use PDFTiny;
my $page = PDFTiny.new.add-page;
use PDF::Content;
use PDF::Content::Font::CoreFont;
use PDF::Content::Text::Block;
my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my $text = "Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my PDF::Content::Text::Box $text-box .= new( :$text, :$font, :font-size(16) );
my PDF::Content $gfx = $page.gfx;
$gfx.BeginText;
$text-box.render($gfx);
$gfx.EndText;
say $gfx.Str;
=end code

=head2 Description

=para Text boxes are used to implement the L<PDF::Content> C<print> and C<say> methods. They usually work "behind the scenes". But can be created as objects and then passed to C<print> and C<say>:

=begin code :lang<raku>
use PDF::Lite;
use PDF::Content;
use PDF::Content::Text::Box;

my PDF::Lite $pdf .= new;

my $font-size = 16;
my $height = 20;
my $text = "Hello.  Ting, ting-ting.";

my PDF::Content::Font::CoreFont $font .= load-font( :family<helvetica>, :weight<bold> );
my PDF::Content::Text::Box $text-box .= new( :$text, :$font, :$font-size, :$height );

say "width:" ~ $text-box.width;
say "height:" ~ $text-box.height;
say "underline-thickness:" ~ $text-box.underline-thickness;
say "underline-position:" ~ $text-box.underline-position;

my $page = $pdf.add-page;

$page.text: {
    .text-position = 10, 20;
    .say: $text-box;
    .text-position = 10, 50;
    .print: $text-box;
}

$pdf.save-as: "test.pdf";
=end code

=head2 Methods

=head3 method text

=para The text contained in the text box. This is a C<rw> accessor. It can also
be used to replace the text contained in a text box.

=head3 method width

=para The constraining width for the text box.

=head3 method height

=para The constraining height for the text box.

=head3 method indent

=para The indentation of the first line (points).

=head3 method align

=para Horizontal alignment C<left>, C<center>, or C<right>.

=head3 method valign

=para Vertical alignment of mutiple-line text boxes: C<top>, C<center>, or C<bottom>.

=para See also the C<:baseline> option for vertical displacement of the first line of text.

=para Note that the baseline is implicitely set to the valign option. However the default for C<valign> is C<top>, and
the default for baseline is C<alphabetic>.

=head3 method baseline

=para The font baseline to use. This is similar to the HTML Canvas L<textBaseline|https://html.spec.whatwg.org/multipage/canvas.html#dom-context-2d-textbaseline> property.

=head3 method baseline-shift

=para Vertical displacement, in scaled font units, needed to postions the font to the baseline. C<0> for C<alphabetic> baseline.

=head3 method lines

=para An array of L<PDF::Content::Text::Line> objects.

=head3 methods margin-left, margin-bottom, margin-right, margin-top

=para These methods adjust the margin placed around a text box.

=para They have no direct affect on rendering, except that the L<PDF::Content> C<print()> and C<say()> methods, which returns the bbox around the rendered text. Note that margins can be negative, to trim text boxes.

=head3 method offset

=para A two member array giving the C<x,y> displacement of the text, by default C<[0, 0]>. These can be set to fine-tune the positioning of the text.

=head3 method bbox

=para The text-boxes bounding box, including margin and offset adjustments.

=begin para
The C<bbox()> method is defined as
=begin code :lang<raku>
[ $tb.offset[0] - $tb.margin-left,   # x0
  $tb.offset[1] - $tb.margin-bottom, # y0
  $tb.offset[0] + $tb.width + $tb.margin-right, #x1
  $tb.offset[1] + $tb.height + $tb.margin-top   #y1
]
=end code
for a given paragraph.
=end para

use PDF::Content::Text::Style;
use PDF::Content::Text::Line;
use PDF::Content::Ops :OpCode, :TextMode;
use PDF::Content::XObject;

my subset Alignment of Str is export(:Alignment) where 'left'|'center'|'right'|'justify'|'start'|'end';
my subset VerticalAlignment of Str is export(:VerticalAlignment) where 'top'|'center'|'bottom';

has Numeric $.width;
has Numeric $.height;
has Numeric $.indent = 0;

has Alignment $.align = 'start';
has VerticalAlignment $.valign;
has PDF::Content::Text::Style $.style is rw handles <font font-size leading kern WordSpacing CharSpacing HorizScaling TextRender TextRise baseline-shift space-width underline-position underline-thickness font-height shape direction script lang>;
has PDF::Content::Text::Line @.lines is built;
has @.overflow is rw is built;
has @.images is built;
has Str $.text is built;
has Bool $.squish = False;
has Bool $.verbatim;
has Bool $.bidi;
has Numeric $.max-word-gap;
has Numeric @.offset[2];
has Numeric $.margin-left   is rw;
has Numeric $.margin-bottom is rw;
has Numeric $.margin-top    is rw;
has Numeric $.margin-right  is rw;
has Str:D   $.baseline = $!valign // 'alphabetic';

method bidi { $!bidi //= $!text.&has-bidi-controls(); }
multi sub has-bidi-controls(Str:U) { False }
multi sub has-bidi-controls(Str:D $_) {
    .contains(/<[ \x2066..\x2069 \x202A..\x202E ]>/)
}

=head3 method style
=for code :lang<raku>
method style() returns PDF::Content::Text::Style

=para Styling delegate for this text box. See L<PDF::Content::Text::Style>

=para This method also handles method C<font>, C<font-size>, C<leading>, C<kern>, C<WordSpacing>, C<CharSpacing>, C<HorizScaling>, C<TextRender>, C<TextRise>, C<baseline-shift>, C<space-width>, C<underline-position>, C<underline-thickness>, C<font-height>. For example C<$tb.font-height> is equivalent to C<$tb.style.font-height>.

#| return the actual width of content in the text box
method content-width returns Numeric  { @!lines».content-width.max; }
=para Calculated from the longest line in the text box.

#| return the actual height of content in the text box
method content-height returns Numeric { @!lines».height.sum * $.leading; }
=para Calculated from the number of lines in the text box.

my grammar Text {
    token nbsp   { <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> }
    token space  { [\s <!after <nbsp> > | \c[ZERO WIDTH SPACE] ]+ }
    token hyphen { <[ \c[HYPHEN] \c[HYPHEN-MINUS] \c[HYPHENATION POINT] ]> }
    token word   { [ <!hyphen> <!space> . ]+ <[ \c[HYPHEN] \c[HYPHEN-MINUS] ]>? | <.hyphen> }
}

#| break a text string into word and whitespace fragments
method comb(Str $_ --> Seq) {
    .comb(/<Text::word> | <Text::space>/);
}

#| clone a text box
method clone(
    ::?CLASS:D:
    :$style = $!style.clone,
    :$text = $!text ~ @!overflow.join,
    |c --> ::?CLASS:D) {
    $style.TWEAK: |c;
    given callwith(:$style, |c) {
        .TWEAK: :$text, |c;
        $_;
    }
}

method text(::?CLASS:D $obj:) is rw {
    Proxy.new(
        FETCH => { $!text },
        STORE => -> $, $!text {
            my @chunks = $obj.comb($!text);
            $obj!layup: @chunks;
        },
    );
}

method !build(
    Numeric :$margin = 0,
    |c) is hidden-from-backtrace  {
    $_ .= new(:$!baseline, |c) without $!style;
    given $!align {
        when 'start' { $_ = $.direction eq 'ltr' ?? 'left' !! 'right' }
        when 'end'   { $_ = $.direction eq 'rtl' ?? 'left' !! 'right' }
    }
    $!valign //= 'top';
    $!max-word-gap //= 10 * self!word-gap;
    @!offset[0] //= 0;
    @!offset[1] //= 0;
    $!margin-left   //= $margin;
    $!margin-bottom //= $margin;
    $!margin-right  //= $margin;
    $!margin-top    //= $margin;
}

multi submethod TWEAK(Str :$!text!, :@chunks = self.comb($!text), |c) {
    self!build: |c;
    self!layup: @chunks;
}

multi submethod TWEAK(:@chunks!, :$!text = @chunks».Str.join, |c) {
    self!build: |c;
    self!layup: @chunks;
}

method !layup(@atoms is copy) {
    my Int $i = 0;
    my Int $line-start = 0;
    my Int $n = +@atoms;
    my $em-spaces = self!word-gap($!style.scale: 1000) / self!word-gap;
    my Numeric $preceding-spaces = self!flush-spaces: $em-spaces, @atoms, $i;
    my $word-gap := self!word-gap;
    my $height := $!style.font-size;
    my Bool $prev-soft-hyphen;

    my PDF::Content::Text::Line $line .= new: :$word-gap, :$height, :$!indent;
    @!lines = $line;

    LAYUP: while $i < $n {
        my subset StrOrImage where Str | PDF::Content::XObject;
        my StrOrImage $atom = @atoms[$i++];
        my Bool $xobject = False;
        my Int $line-breaks = 0;
        my Numeric $word-pad = $preceding-spaces * $word-gap;
        my Bool $soft-hyphen;
        my List $word;
        my Numeric $word-width;

        :($word, $word-width) := do given $atom {
            when "\c[HYPHENATION POINT]" {
                $soft-hyphen = True;
                $atom = $!style.hyphen;
                $!style.hyphen-encoding;
            }
            when Str {
                if $!verbatim && .match("\n", :g) -> UInt() $nl {
                    # todo: handle tabs
                    $line-breaks = $nl;
                    $atom = ' ' x $preceding-spaces;
                    $word-pad = 0;
                }
                $!style.encode: $atom;
            }
            when PDF::Content::XObject {
                $xobject = True;
                [-.width * $.HorizScaling * 10 / $!style.font-size, ], .width;
            }
        }

        if $!width && !$line-breaks && ($line.encoded || $line.indent) {
            my $test-width = $line.content-width + $word-pad + $word-width;
            $test-width += $!style.hyphen-width
                if @atoms[$i] ~~ "\c[HYPHENATION POINT]";

            $line-breaks = $test-width > $!width
        }

        while $line-breaks-- {
            $prev-soft-hyphen = False;
            $line-start = $i;
            $line .= new: :$word-gap, :$height;
            @!lines.push: $line;
            $preceding-spaces = 0;
            $word-pad = 0;
            if self!height-exceeded {
                @!lines.pop;
                $i--;
                last LAYUP;
            }
        }

        if $xobject {
            given $atom.height {
                if $_ > $line.height {
                    $line.height = $_;
                    if self!height-exceeded {
                        @!lines.pop;
                        $i = $line-start;
                        last LAYUP;
                    }
                }
            }

            my $Tx = $line.content-width + $word-pad;
            my $Ty = @!lines.head.height * $.leading  -  self.content-height;
            @!images.push( { :$Tx, :$Ty, :xobject($atom) } )
        }

        if $prev-soft-hyphen {
            # Drop soft hyphen when line is continued
            $line.encoded.pop;
            $line.word-width -= $!style.hyphen-width;
        }
        $line.spaces[+$line.encoded] = $preceding-spaces;
        $line.decoded.push: $xobject ?? '' !! $atom;
        $line.encoded.push: $word;
        $line.word-width += $word-width;
        $line.height = $height
            if $height > $line.height;

        $prev-soft-hyphen = $soft-hyphen;
        $preceding-spaces = self!flush-spaces($em-spaces, @atoms, $i);
    }

    if $preceding-spaces {
        # trailing space
        $line.spaces.push($preceding-spaces);
        $line.encoded.push: [];
    }

    @!overflow = @atoms[$i..*];

    if !$!verbatim && ($.bidi || $.direction ne 'ltr') {
        if (try require ::('Text::FriBidi::Lines')) !=== Nil {
            my constant FRIBIDI_PAR_LTR = 272;
            my constant FRIBIDI_PAR_RTL = 273;
            # apply bidi processing
            my Str @lines = @!lines.map: *.text;
            # todo: :lang
            my UInt $direction = $.direction eq 'rtl'
                ?? FRIBIDI_PAR_RTL
                !! FRIBIDI_PAR_LTR;
            my $bidi-lines = ::('Text::FriBidi::Lines').new: :@lines, :$direction;
            my Str() $text = $bidi-lines;
            my ::?CLASS:D $proxy = self.clone: :$text, :verbatim;
            @!lines = $proxy.lines;
        }
        else {
            warn "Text::FriBidi v0.0.4+ is required for :bidi processing";
        }
    }

    my Numeric $width = $.width
        if $!align eq 'justify';

    .align($!align, :$width, :$!max-word-gap )
        for @!lines;

}

method !height-exceeded {
    $!height && self.content-height > $!height;
}

my constant %SpaceWidth = %(
    "\c[EN SPACE]"  => .5,
    "\c[EM SPACE]"  => 1,
    "\c[THREE-PER-EM SPACE]" => 3,
    "\c[FOUR-PER-EM SPACE]" => 4,
    "\c[SIX-PER-EM SPACE]" => 6,
    "\c[THIN SPACE]" => .2,
    "\c[HAIR SPACE]" => .1,
    "\c[ZERO WIDTH SPACE]" => 0,
);

method !flush-spaces($em-spaces is rw, @words is raw, $i is rw) returns Numeric:D {
    my $n = 0; # space count for padding purposes
    with  @words[$i] {
        when /<Text::space>/ {
            if $!verbatim && (my $last-nl = .rindex("\n")).defined {
                # count spaces after last new-line
                $n = .substr($last-nl+1).comb.map({do with %SpaceWidth{$_} { $_ * $em-spaces } // 1}).sum
                    unless $!squish;
            }
            else {
                $i++;
                $n = .comb.map({do with %SpaceWidth{$_} { $_ * $em-spaces } // 1}).sum;
                $n = 1 if $n > 1 && $!squish;
            }
        }
    }
    $n;
}

# calculates actual spacing between words
method !word-gap($space = $.space-width) returns Numeric {
    my $word-gap = $space + $.WordSpacing + $.CharSpacing;
    $word-gap * $.HorizScaling / 100;
}

#| return displacement width of a text box
method width returns Numeric  { $!width  || self.content-width }
#| return displacement height of a text box
method height returns Numeric { $!height || self.content-height }
method !dx { %(:left(0), :justify(0), :center(0.5), :right(1.0) ){$!align} }
method !dy { %(:top(0.0), :center(0.5), :bottom(1.0) ){$!valign} // 0; }

method bbox(Numeric:D $x = @!offset[0], Numeric:D $y = @!offset[1]) {
    ($x - $!margin-left, $y - $!margin-bottom,
     $x + self.width + $!margin-right, $y + self.height + $!margin-top)
}

#| render a text box to a content stream at current or given text position
method render(
    PDF::Content::Ops:D $gfx,
    Bool :$nl,   # add trailing line
    Bool :$preserve = True, # restore text state
    --> List
    ) {
    my %saved;

    for :$.CharSpacing, :$.HorizScaling, :$.TextRise, :$.TextRender {
        my $gval = $gfx."{.key}"();

        unless $gval =~= .value {
            %saved{.key} = $gval
                if $preserve;
            $gfx."{.key}"() = .value;
        }
    }

    $gfx.font = [$_, $!style.font-size // 12]
       with $!style.font;

    my @content;
    @content.push: 'comment' => 'text: ' ~ @!lines>>.text.join(' ').subst(/(<-[\0..\xFF]>)/, { '\u%04d'.sprintf($0.ord)}, :g)
        if $gfx.comment;

    my Numeric:D $lh := @!lines ?? @!lines.head.height !! 0;
    my Numeric:D $y-shift = @!offset[1] + self!dy * ($.height - $lh * $.leading);
    my $leading = $gfx.TextLeading;
    my $tf-y = $gfx.tf-y;

    {
        # work out and move to the text starting position
        my $y-pad = self!dy * ($.height - $.content-height);
        my $tx := $gfx.tf-x + @!offset[0];
        my $ty = $y-shift + $tf-y - $y-pad;
        $ty += $.font-size - $lh if @!lines;
        @content.push( OpCode::TextMove => [$tx, $ty] )
            unless $ty =~= 0.0;
        # offset text positions of images content
        for @!images {
            my Numeric @Tm[6] = $gfx.TextMatrix.list;
            @Tm[4] += .<Tx> + $tx;
            @Tm[5] += .<Ty> + $.TextRise + $ty;
            given .<xobject> {
                if .does(PDF::Content::XObject['Image']) {
                    @Tm[0] *= .width;
                    @Tm[3] *= .height;
                }
            }
            .<Tm> = @Tm;
        }
    }

    my Numeric \scale = -1000 / $.font-size;
    for @!lines.pairs {
        my \line = .value;

        if .key {
            my \lead = line.height * $.leading;
            @content.push: ( OpCode::SetTextLeading => [ $leading = lead ] )
                unless $leading =~= lead;
            @content.push: OpCode::TextNextLine;
        }

        my $space-pad = scale * (line.word-gap - self.space-width);
        @content.push: line.content(:$.font, :$.font-size, :$space-pad, :$.TextRise);
    }

    my $tf-dx = 0;
    if $nl || @!overflow {
        my $height = @!lines ?? @!lines.tail.height !! $.font-size;
        my \lead = $height * $.leading;
        @content.push: ( OpCode::SetTextLeading => [ lead ] )
            unless $leading =~= lead;
        @content.push: OpCode::TextNextLine;
    }
    else {
        with @!lines.tail {
            # compute text flow increment
            $tf-dx += .align + .content-width;
        }
    }

    $gfx.ops: @content;
    $gfx.tf-x += $tf-dx; # add to text-flow;
    $gfx.tf-y = - $y-shift;

    # restore original graphics values
    $gfx."{.key}"() = .value for %saved.pairs;

    my Numeric:D $dx := self!dx * $.width - @!offset[0];
    my Numeric:D $dy := $y-shift - $.height + $.font-size + $tf-y + $.TextRise;
    (- $dx , $dy);
}

#| flow any xobject images. This needs to be done
#| after rendering and exiting text block
method place-images($gfx) {
    for self.images {
        $gfx.Save;
        $gfx.ConcatMatrix: |.<Tm>;
        given .<xobject> {
            .finish if .does(PDF::Content::XObject['Form']);
        }
        $gfx.XObject: $gfx.resource-key(.<xobject>);
        $gfx.Restore;
    }
}

#| return text split into lines
method Str returns Str {
    @!lines>>.text.join: "\n";
}

