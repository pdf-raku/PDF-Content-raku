use v6;

#| simple plain-text text blocks
class PDF::Content::Text::Block {

    use PDF::Content::Text::Style :Alignment;
    use PDF::Content::Text::Line;
    use PDF::Content::Ops :OpCode, :TextMode;
    use PDF::Content::Marked :ParagraphTags;
    use PDF::Content::Replaced;

    has PDF::Content::Text::Style $!style handles <font font-size leading valign kern text-rise space-width baseline>; 
    has Numeric $.width;
    has Numeric $.height;
    has @.lines;
    has @.overflow is rw;
    has ParagraphTags $.type = Paragraph;
    has @.replaced;
    has Str $.text;

    # current graphics state
    has PDF::Content::Ops $.gfx is required;

    method content-width  { @!lines.map( *.content-width ).max }
    method content-height {
        sum @!lines.map( *.leading )
    }

    my grammar Text {
        token nbsp  { <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> }
        token space { [\s <!after <nbsp> >]+ }
        token word  { [ <![ - ]> <!before <space>> . ]+ '-'? | '-' }
    }

    method comb(Str $_) {
        .comb(/<Text::word> | <Text::space>/);
    }

    multi submethod TWEAK(Str :$!text!, |c) {
        my Str @chunks = self.comb: $!text;
        self.TWEAK( :@chunks, |c );
    }

    multi submethod TWEAK(:@chunks!, Bool :$kern = False, |c) is default {

	$!style .= new(|c);
        my @atoms = @chunks; # copy
        my @line-atoms;
        my Bool $follows-ws = False;
        my $word-gap = self!word-gap;
        $!text //= @atoms.map(*.Str).join;
	my $leading = $!style.leading;

        my PDF::Content::Text::Line $line .= new: :$word-gap, :$leading;
        @!lines.push: $line;

        flush-space(@atoms);
  
        while @atoms {
            my subset StrOrReplaced where Str | PDF::Content::Replaced;
            my StrOrReplaced $atom = @atoms.shift;
            my Bool $replacing = False;
	    my $word-width;
            my $word;
            my $pre-word-gap = $follows-ws ?? $word-gap !! 0.0;

            given $atom {
                when Str {
                    if ($kern) {
                        ($word, $word-width) = $!style.font.kern($atom);
                    }
                    else {
                        $word = [ $atom, ];
                        $word-width = $!style.font.stringwidth($atom);
                    }
                    $word-width *= $!style.font-size * $!gfx.HorizScaling / 100000;
                    $word-width += ($atom.chars - 1) * $!gfx.CharSpacing
                        if $!gfx.CharSpacing > -$!style.font-size;

                    for $word.list {
                        when Str {
                            $_ = $!style.font.encode($_).join;
                        }
                        when Numeric {
                            $_ = -$_;
                        }
                    }
                }
                when PDF::Content::Replaced {
                    $replacing = True;
                    $word = [-$atom.width * $!gfx.HorizScaling * 10 / $!style.font-size, ];
                    $word-width = $atom.width;
                }
            }

            if $!width && $line.words && $line.content-width + $pre-word-gap + $word-width > $!width {
                # line break
                $line = $line.new: :$word-gap, :$leading;
                @!lines.push: $line;
                @line-atoms = [];
                $follows-ws = False;
                $pre-word-gap = 0;
            }
            if $replacing {
                my $lead = $atom.height * 1.1; # review this
                $line.leading = $lead
                    if $lead > $line.leading;
            }
            if $!height && self.content-height > $!height {
                # height exceeded
                @!lines.pop if @!lines;
                @!overflow.append: @line-atoms;
                last;
            }

            if $replacing {
                my $Tx = $line.content-width + $pre-word-gap;
                my $Ty = $line.leading - self.content-height;
                @!replaced.push( { :$Tx, :$Ty, :source($atom.source) } )
            }

            @line-atoms.push: $atom;
            $line.word-boundary[+$line.words] = $follows-ws;
            $line.words.push: $word;
            $line.word-width += $word-width;

            $follows-ws = flush-space(@atoms);
        }

        @!overflow.append: @atoms;

        my $width = $!width // self.content-width
            if $!style.align eq 'justify';

        .align($!style.align, :$width )
            for @!lines;
    }

    sub flush-space(@words) returns Bool {
        my Bool \flush = ? (@words && @words[0] ~~ /<Text::space>/);
        @words.shift if flush;
        flush;
    }

    #| calculates actual spacing between words
    method !word-gap returns Numeric {
        my $word-gap = $.space-width + $!gfx.WordSpacing + $!gfx.CharSpacing;
        $word-gap *= $!gfx.HorizScaling / 100
            unless $!gfx.HorizScaling =~= 100;
        $word-gap;
    }

    #| calculates WordSpacing needed to achieve a given word-gap
    method !word-spacing($word-gap is copy) returns Numeric {
        $word-gap /= $!gfx.HorizScaling / 100
            unless $!gfx.HorizScaling =~= 100;
        $word-gap - $.space-width - $!gfx.CharSpacing;
    }

    method width  { $!width  // self.content-width }
    method height { $!height // self.content-height }
    method !dy {
        given $.valign {
            when 'center' { 0.5 }
            when 'bottom' { 1.0 }
            default       { 0 }
        };
    }
    method top-offset {
        self!dy * ($.height - $.content-height);
    }

    method align(Alignment $align) {
        $!style.align = $align;
        .align($align)
            for self.lines;
    }

    method render(
	PDF::Content::Ops $gfx = $!gfx,
	Bool :$nl,   # add trailing line 
	Bool :$top,  # position from top
	Bool :$left, # position from left;
	) {

        my @content;
	my $space-size = -(1000 * $.space-width / $.font-size).round.Int;

        my $y-shift = $top ?? - $.top-offset !! self!dy * $.height;
        $y-shift -= self.text-rise;
        @content.push( OpCode::TextMove => [0, $y-shift ] )
            unless $y-shift =~= 0.0;

        my $dx = do given $!style.align {
            when 'center' { 0.5 }
            when 'right'  { 1.0 }
            default       { 0.0 }
        }
        my $x-shift = $left ?? $dx * $.width !! 0.0;
        # compute text positions of replaced content
        for @!replaced {
            my @Tm = $gfx.TextMatrix;
            @Tm[4] += $x-shift + .<Tx>;
            @Tm[5] += $y-shift + .<Ty>;
            .<Tm> = @Tm;
        }

        my $word-spacing = $gfx.WordSpacing;
        my $leading = $gfx.TextLeading;

        for @!lines -> \line {
            with self!word-spacing(line.word-gap) {
                @content.push( OpCode::SetWordSpacing => [ $word-spacing = $_ ])
                    unless $_ =~= $word-spacing || +line.words <= 1;
            }
            my Bool $lead = ? ($nl || +@!lines > 1)
		&& (!$gfx.TextLeading.defined || $leading !=~= line.leading);
            @content.push: ( OpCode::SetTextLeading => [ $leading = line.leading ] )
                if $lead;
            @content.push: line.content(:$.font-size, :$x-shift);
            @content.push: OpCode::TextNextLine;
        }

        @content.pop
            if !$nl && @content;

        # restore original values
        @content.push( OpCode::SetWordSpacing => [ $gfx.WordSpacing ])
            unless $gfx.WordSpacing =~= $word-spacing;

        $gfx.ops: @content;
	@content;
    }

}
