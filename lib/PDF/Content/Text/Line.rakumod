#| A single line of a text box
unit class PDF::Content::Text::Line;

=head2 Description

=para This class represents a single line of output in a L<PDF::Content::Text::Box>.

=head2 Methods

=head3 method text

=para Return the input text for the line.

=head3 method decoded

=para Return a list of input text atoms

=head3 method encoded

=para An list of font encodings

=head3 method height

=para Height of the line.

=head3 method word-gap

=para Spacing between words.

=head3 method indent

=para indentation offset.

=head3 method align

=para Alignment offset.

=head3 method content-width

=para Return the width of rendered content.

use PDF::Content::Ops :OpCode;
use Method::Also;

has Str @.decoded;
has List @.encoded;
has Numeric $.height is rw is required;
has Numeric $.word-width is rw = 0;
has Numeric $.word-gap is rw = 0;
has Numeric $.indent is rw = 0;
has Numeric $.align = 0;
has Numeric @.spaces;

method content-width returns Numeric {
    $!indent  +  $!word-width  +  @!spaces.sum * $!word-gap;
}

multi method align('justify', Numeric :$width!, Numeric:D :$max-word-gap! ) {
    my Numeric \content-width = $.content-width;
    my Numeric \wb = +@!spaces.sum;

    if content-width && wb && $width >= content-width {
        given $!word-gap + ($width - content-width) / wb {
            $!word-gap = $_
                unless $_ > $max-word-gap;
        }
        $!align = 0;
    }
}

multi method align('left') {
    $!align = 0;
}

multi method align('right') {
    $!align = - $.content-width;
}

multi method align('center') {
    $!align = - $.content-width  /  2;
}

multi method align { $!align }

sub coalesce(@line is raw) {
    my @l;
    my $prev;
    for @line {
        if $_ ~~ Str && $prev ~~ Str {
            @l.tail ~= $_;
        }
        else {
            @l.push: $_;
            $prev := $_;
        }
    }
    @l;
}

multi sub render2D(@atoms, :$scale, :$TextRise!) {
    my @segs;
    my Array $chunk = [];
    my Int $y = 0;
    my $text-rise = $TextRise;

    for @atoms {
        if .isa(Complex) {
            my $new-rise = $TextRise + .im.round / $scale;
            unless $new-rise =~= $text-rise {
                $text-rise := $new-rise;
                @segs.push: render(@$chunk) if $chunk;
                @segs.push: 'Ts' => [$text-rise];
                $chunk = [];
            }
            $chunk.push: .re if .re;
        }
        else {
            $chunk.push: $_;
        }
    }

    @segs.push: render(@$chunk) if $chunk;

    if ($text-rise !=~= $TextRise) {
        # restore
        @segs.push: 'Ts' => [$TextRise];
    }

    @segs.Slip;
}

multi sub render(@atoms where .elems == 1 && .head.isa(Str)) {
    (OpCode::ShowText) => [@atoms.head,];
}

multi sub render(@atoms) {
    (OpCode::ShowSpaceText) => [@atoms,];
}

method content(:$font!, Numeric :$font-size!, :$space-pad = 0, :$TextRise = 0.0) {
    my Numeric $scale = -1000 / $font-size;
    my subset Atom where Str|Numeric;
    my Atom @line;
    constant Space = ' ';
    my int $wc = 0;

    if $!align + $!indent -> $indent {
        @line.push: ($indent * $scale).round.Int;
    }

    # flatten words. insert spaces and space adjustments.
    # Ensure we add spaces - as recommended in [PDF-32000 14.8.2.5 - Identifying Word Breaks]
    for ^+@!encoded -> $i {
        if @!spaces[$i] -> $spaces {
            my UInt $whole-spaces = $spaces.floor;
            my $part-spaces = $spaces - $whole-spaces;
            unless $whole-spaces {
                $whole-spaces++;
                $part-spaces--;
            }
            @line.push: $font.encode(Space x $whole-spaces);
            my Int $pad = round($space-pad * $spaces + -1000 * $part-spaces * $!word-gap / $font-size);
            @line.push: $pad
                if $pad;
        }
        @line.append: @!encoded[$i].list;
    }
    @line .= &coalesce;

    @line.first(Complex)
    ?? render2D(@line, :$scale, :$TextRise)
    !! render(@line);
}

method text is also<Str> {
    join '', @!decoded.kv.map: -> $i, $w {
        ((' ' x @!spaces[$i]).Slip, $w)
    }
}

