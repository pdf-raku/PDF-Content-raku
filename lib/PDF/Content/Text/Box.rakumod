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

=para See also the :baseline` option for vertical displacememnt of the first line of text.

=head3 method lines

=para An array of L<PDF::Content::Text::Line> objects.

=head3 methods pad-left, pad-bottom, pad-right, pad-top, bbox

=para These methods allow extra padding to be placed around a text box.

=para They have no direct affect on rendering, except that the L<PDF::Content> C<print()> and <say()> methods, which return padded values.

=para the C<bbox()> method is defined as C<[-$tb.pad-left, -$tb.pad-bottom, $tb.width + $tb.pad-right, $tb.height + $tb.pad-top]>,
for a given paragraph.

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
has Numeric $.pad-left   is rw;
has Numeric $.pad-bottom is rw;
has Numeric $.pad-top    is rw;
has Numeric $.pad-right  is rw;

method bidi { $!bidi //= $!text.&has-bidi-controls(); }
multi sub has-bidi-controls(Str:U) { False }
multi sub has-bidi-controls(Str:D $_) {
    .contains(/<[ \x2066..\x2069 \x202A..\x202E ]>/)
}

=head2 style
=for code :lang<raku>
method style() returns PDF::Content::Text::Style

=para Styling delegate for this text box. SeeL<PDF::Content::Text::Style>

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
method clone(::?CLASS:D: :$text = $!text ~ @!overflow.join, |c --> ::?CLASS:D) {
    given callwith(|c) {
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

method !build-style(
    :$baseline = $!valign // 'alphabetic',
    Numeric :$pad = 0,
    :@bbox,
    |c) is hidden-from-backtrace  {
    $_ .= new(:$baseline, |c) without $!style;
    given $!align {
        when 'start' { $_ = $.direction eq 'ltr' ?? 'left' !! 'right' }
        when 'end'   { $_ = $.direction eq 'rtl' ?? 'left' !! 'right' }
    }
    $!valign //= 'top';
    $!max-word-gap //= 10 * self!word-gap;
    $!pad-left   //= $pad;
    $!pad-bottom //= $pad;
    $!pad-right  //= $pad;
    $!pad-top    //= $pad;
    self.bbox = @bbox if @bbox;
}

multi submethod TWEAK(Str :$!text!, :@chunks = self.comb($!text), |c) {
    self!build-style: |c;
    self!layup: @chunks;
}

multi submethod TWEAK(:@chunks!, :$!text = @chunks».Str.join, |c) {
    self!build-style: |c;
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
        my List $word;
        my Numeric $word-width = 0;
        my Numeric $word-pad = $preceding-spaces * $word-gap;
        my Bool $soft-hyphen;

        given $atom {
            when Str {
                my $enc;
                if $atom eq "\c[HYPHENATION POINT]" {
                    $atom = $!style.hyphen;
                    $enc  = $!style.hyphen-encoding;
                    $soft-hyphen = True;
                }
                else {
                    if $!verbatim && +.match("\n", :g) -> UInt $nl {
                        # todo: handle tabs
                        $line-breaks = $nl;
                        $atom = ' ' x $preceding-spaces;
                        $word-pad = 0;
                    }
                    $enc = $!style.encode: $atom;
                }
                $word = $enc[0];
                $word-width = $enc[1];
            }
            when PDF::Content::XObject {
                $xobject = True;
                $word = [-$atom.width * $.HorizScaling * 10 / $!style.font-size, ];
                $word-width = $atom.width;
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

    my $width = $.width
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

method bbox is rw {
    sub FETCH($_) {
        [-$!pad-left, -$!pad-bottom, self.width + $!pad-right, self.height + $!pad-top]
    }
    sub STORE($, @bbox where .elems >= 4) {
        $!pad-left   = -@bbox[0];
        $!pad-bottom = -@bbox[1];
        $!pad-right  =  @bbox[2] - self.width;
        $!pad-top    =  @bbox[3] - self.height;
    }
    Proxy.new: :&FETCH, :&STORE;
}

#| render a text box to a content stream at current or given text position
method render(
    PDF::Content::Ops:D $gfx,
    Bool :$nl,   # add trailing line
    Bool :$top,  # position from top
    Bool :$left, # position from left
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
    my Numeric:D $top-pad := self!dy * ($.height - $.content-height);
    my Numeric:D $y-shift := $top ?? - $top-pad !! self!dy * ($.height - $lh * $.leading);
    my $tf-y = $gfx.tf-y;
    my Numeric:D $dx := self!dx * $.width;
    my $x-shift = $left ?? $dx !! 0.0;
    my $leading = $gfx.TextLeading;
    my Numeric \scale = -1000 / $.font-size;

    {
        # work out and move to the text starting position
        my $tx := $x-shift + $gfx.tf-x;
        my $ty = $y-shift + $tf-y - $top-pad;
        $ty += $.font-size - $lh if @!lines;
        @content.push( OpCode::TextMove => [$tx, $ty] )
            unless $x-shift =~= 0 && $ty =~= 0.0;
        # offset text positions of images content
        for @!images {
            my Numeric @Tm[6] = $gfx.TextMatrix.list;
            @Tm[4] += .<Tx> + $tx;
            @Tm[5] += .<Ty> + $.TextRise + $ty;
            .<Tm> = @Tm;
        }
    }

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

    ($x-shift - $dx, $y-shift - $.height + $lh + $tf-y);
}

#| flow any xobject images. This needs to be done
#| after rendering and exiting text block
method place-images($gfx) {
    for self.images {
        $gfx.Save;
        $gfx.ConcatMatrix: |.<Tm>;
        .<xobject>.finish;
        $gfx.XObject: $gfx.resource-key(.<xobject>);
        $gfx.Restore;
    }
}

#| return text split into lines
method Str returns Str {
    @!lines>>.text.join: "\n";
}

