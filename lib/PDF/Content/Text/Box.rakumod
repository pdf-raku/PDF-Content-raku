#| simple plain-text blocks
class PDF::Content::Text::Box {

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
    has PDF::Content::Text::Style $.style is rw handles <font font-size leading kern WordSpacing CharSpacing HorizScaling TextRender TextRise baseline-shift space-width underline-position underline-thickness font-height>;
    has PDF::Content::Text::Line @.lines is built;
    has @.overflow is rw is built;
    has @.images is built;
    has Str $.text is built;
    has Bool $.squish = False;
    has Bool $.verbatim;

    method content-width  { @!lines».content-width.max; }
    method content-height { @!lines».height.sum * $.leading; }

    my grammar Text {
        token nbsp  { <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> }
        token space { [\s <!after <nbsp> >]+ }
        token word  { [ <![ - ]> <!before <space>> . ]+ '-'? | '-' }
    }

    method comb(Str $_) {
        .comb(/<Text::word> | <Text::space>/);
    }

    method clone(::?CLASS:D: :$text = $!text ~ @!overflow.join, |c) {
        given callwith(|c) {
            .TWEAK: :$text;
            $_;
        }
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
        my $word-gap = self!word-gap;
	my $height = $!style.font-size;

        my PDF::Content::Text::Line $line .= new: :$word-gap, :$height, :$!indent;
	@!lines = [ $line ];

        LAYUP: while $i < $n {
            my subset StrOrImage where Str | PDF::Content::XObject;
            my StrOrImage $atom = @atoms[$i++];
            my Bool $xobject = False;
            my $line-breaks = 0;
            my List $word;
	    my $word-width = 0;
            my $word-pad = $preceding-spaces * $word-gap;

            given $atom {
                when Str {
                    if $!verbatim && +.match("\n", :g) -> $nl {
                        # todo: handle tabs
                        $line-breaks = $nl;
                        $atom = ' ' x $preceding-spaces;
                        $word-pad = 0;
                    }

                    if $!style.kern {
                        given $!style.font.kern($atom) {
                            $word = .List given .[0].list.map: {
                                .does(Numeric) ?? -$_ !! $_;
                            }
                            $word-width = .[1];
                        }
                    }
                    else {
                        $word = [ $atom, ];
                        $word-width = $!style.font.stringwidth($atom);
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

            while $line-breaks--  {
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

    #| calculates actual spacing between words
    method !word-gap returns Numeric {
        my $word-gap = $.space-width + $.WordSpacing + $.CharSpacing;
        $word-gap * $.HorizScaling / 100;
    }

    method width  { $!width  || self.content-width }
    method height { $!height || self.content-height }
    method !dy {
        %( :center(0.5), :bottom(1.0) ){$!valign}
            // 0;
    }
    method !top-offset {
        self!dy * ($.height - $.content-height);
    }

    method render(
	PDF::Content::Ops:D $gfx,
	Bool :$nl,   # add trailing line
	Bool :$top,  # position from top
	Bool :$left, # position from left
	Bool :$preserve = True, # restore text state
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

        my $y-shift = $top ?? - self!top-offset !! self!dy * $.height;
        @content.push( OpCode::TextMove => [0, $y-shift ] )
            unless $y-shift =~= 0.0;

        my $dx = %( :center(0.5), :right(1.0) ){$!align}
           // 0.0;

        my $x-shift = $left ?? $dx * $.width !! 0.0;
        # compute text positions of images content
        for @!images {
            my Numeric @Tm[6] = $gfx.TextMatrix.list;
            @Tm[4] += $x-shift + .<Tx> + $.TextRise;
            @Tm[5] += $y-shift + .<Ty>;
            .<Tm> = @Tm;
        }

        my $leading = $gfx.TextLeading;
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
            @content.push: line.content(:$.font, :$.font-size, :$x-shift, :$space-pad);
        }

	if $nl || @!overflow {
	    my $height = @!lines ?? @!lines.tail.height !! $.font-size;
            my \lead = $height * $.leading;
	    @content.push: ( OpCode::SetTextLeading => [ lead ] )
                unless $leading =~= lead;
	    @content.push: OpCode::TextNextLine;
	}

        $gfx.ops: @content;
        # restore original graphics values
        $gfx."{.key}"() = .value for %saved.pairs;

	($x-shift, $y-shift);
    }

    # flow any xobject images. This needs to be done
    # after rendering and exiting text block
    method place-images($gfx) {
        for self.images {
            $gfx.Save;
            $gfx.ConcatMatrix: |.<Tm>;
            .<xobject>.finish;
            $gfx.XObject: $gfx.resource-key(.<xobject>);
            $gfx.Restore;
        }
    }

    method Str {
        @!lines>>.text.join: "\n";
    }
}
