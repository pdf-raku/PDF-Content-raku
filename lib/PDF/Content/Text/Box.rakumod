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

use PDF::Content::Text::Style;
use PDF::Content::Text::Line;
use PDF::Content::Ops :OpCode, :TextMode;
use PDF::Content::XObject;

my subset Alignment of Str is export(:Alignment) where 'left'|'center'|'right'|'justify';
my subset VerticalAlignment of Str is export(:VerticalAlignment) where 'top'|'center'|'bottom';

has Numeric $.width;
has Numeric $.height;
has Numeric $.indent = 0;

has Alignment $.align = 'left';
has VerticalAlignment $.valign = 'top';
has PDF::Content::Text::Style $.style is rw handles <font font-size leading kern WordSpacing CharSpacing HorizScaling TextRender TextRise baseline-shift space-width underline-position underline-thickness font-height shape>;
has PDF::Content::Text::Line @.lines is built;
has @.overflow is rw is built;
has @.images is built;
has Str $.text is built;
has Bool $.squish = False;
has Bool $.verbatim;

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
    token nbsp  { <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> }
    token space { [\s <!after <nbsp> >]+ }
    token word  { [ <![ - ]> <!before <space>> . ]+ '-'? | '-' }
}

#| break a text string into word and whitespace fragments
method comb(Str $_ --> Seq) {
    .comb(/<Text::word> | <Text::space>/);
}

#| clone a text box
method clone(::?CLASS:D: :$text = $!text ~ @!overflow.join, |c --> ::?CLASS:D) {
    given callwith(|c) {
        .TWEAK: :$text;
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

multi submethod TWEAK(Str :$!text!, :@chunks = self.comb($!text), |c) {
    $_ .= new(|c) without $!style;
    self!layup: @chunks;
}

multi submethod TWEAK(:@chunks!, :$!text = @chunks».Str.join, |c) {
    $_ .= new(|c) without $!style;
    self!layup: @chunks;
}

method !layup(@atoms is copy) {
    my int $i = 0;
    my int $line-start = 0;
    my int $n = +@atoms;
    my UInt $preceding-spaces = self!flush-spaces: @atoms, $i;
    my $word-gap := self!word-gap;
    my $height := $!style.font-size;
    my $font := $!style.font;
    my Bool $kern := $!style.kern;
    my Bool $shape := $!style.shape;

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

        given $atom {
            when Str {
                if $!verbatim && +.match("\n", :g) -> $nl {
                    # todo: handle tabs
                    $line-breaks = $nl;
                    $atom = ' ' x $preceding-spaces;
                    $word-pad = 0;
                }

                if $shape {
                    given $font.shape($atom) {
                        $word = .[0];
                        $word-width = .[1];
                    }
                }
                elsif $kern {
                    given $!style.font.kern($atom) {
                        $word = .List given .[0].list.map: {
                            .does(Numeric) ?? -$_ !! $font.encode($_);
                        }
                        $word-width = .[1];
                    }
                }
                else {
                    $word = [ $font.encode($atom), ];
                    $word-width = $font.stringwidth($atom);
                }
                $word-width *= $!style.font-size * $.HorizScaling / 100000;
                $word-width += ($atom.chars - 1) * $.CharSpacing
                    if $.CharSpacing > -$!style.font-size;
            }
            when PDF::Content::XObject {
                $xobject = True;
                $word = [-$atom.width * $.HorizScaling * 10 / $!style.font-size, ];
                $word-width = $atom.width;
            }
        }

        $line-breaks ||= ($line.words || $line.indent) && $line.content-width + $word-pad + $word-width > $!width
            if $!width;

        while $line-breaks-- {
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

        $line.spaces[+$line.words] = $preceding-spaces;
        $line.words.push: $word;
        $line.word-width += $word-width;
        $line.height = $height
            if $height > $line.height;

        $preceding-spaces = self!flush-spaces(@atoms, $i);
    }

    if $preceding-spaces {
        # trailing space
        $line.spaces.push($preceding-spaces);
        $line.words.push: [];
    }

    @!overflow = @atoms[$i..*];
}

method !height-exceeded {
    $!height && self.content-height > $!height;
}

method !flush-spaces(@words is raw, $i is rw) returns UInt {
    my $n = 0; # space count for padding purposes
    with  @words[$i] {
        when /<Text::space>/ {
            $n = .chars;
            if $!verbatim && (my $last-nl = .rindex("\n")).defined {
                # count spaces after last new-line
                $n -= $last-nl + 1;
                $n = 0 if $!squish;
            }
            else {
                $i++;
                $n = 1 if $!squish;
            }
        }
    }
    $n;
}

# calculates actual spacing between words
method !word-gap returns Numeric {
    my $word-gap = $.space-width + $.WordSpacing + $.CharSpacing;
    $word-gap * $.HorizScaling / 100;
}

#| return displacement width of a text box
method width returns Numeric { $!width  || self.content-width }
#| return displacement height of a text box
method height returns Numeric { $!height || self.content-height }
method !dy {
    %(:top(0.0), :center(0.5), :bottom(1.0) ){$!valign}
        // 0;
}
method !top-offset {
    self!dy * ($.height - $.content-height);
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
    my Bool $gsave;

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

    my $width = $.width
        if $!align eq 'justify';

    .align($!align, :$width )
        for @!lines;

    my @content;
    @content.push: 'comment' => 'text: ' ~ @!lines>>.text.join: ' '
        if $gfx.comment;

    my $h = @!lines ?? @!lines.head.height !! 0;
    my Numeric:D $y-shift = $top ?? - self!top-offset !! self!dy * ($.height - $h * $.leading);
    my $tf-y = $gfx.tf-y;
    my Numeric:D $dx = %(:left(0), :justify(0), :center(0.5), :right(1.0) ){$!align} * $.width;
    my $x-shift = $left ?? $dx !! 0.0;
    my $leading = $gfx.TextLeading;
    my Numeric \scale = -1000 / $.font-size;

    {
        # work out and move to the text starting position
        my $y-pad = self!dy * ($.height - $.content-height);
        my $tx := $x-shift + $gfx.tf-x;
        my $ty := $y-shift + $tf-y - $y-pad;
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
        @content.push: line.content(:$.font, :$.font-size, :$space-pad);
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
    unless $gfx.TextRender == InvisableText {
        $gfx.tf-x += $tf-dx; # add to text-flow;
        $gfx.tf-y = - $y-shift;
    }
    # restore original graphics values
    $gfx."{.key}"() = .value for %saved.pairs;

    ($x-shift - $dx, $y-shift - $.height + $h + $tf-y);
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

