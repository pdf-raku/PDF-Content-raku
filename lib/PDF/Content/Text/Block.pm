use v6;

#| simple plain-text text blocks
class PDF::Content::Text::Block {

    use PDF::Content::Text::Line;
    use PDF::Content::Ops :OpCode, :TextMode;
    use PDF::Content::Marked :ParagraphTags;
    use PDF::Content::Replaced;

    has         $.font is required;
    has Numeric $.font-size = 16;
    has Numeric $.leading = $!font-size * 1.1;
    my subset Baseline of Str where 'alphabetic'|'top'|'bottom'|'middle'|'ideographic'|'hanging';
    has Baseline $.baseline is rw = 'alphabetic';
    has Numeric $!space-width = $!font.stringwidth(' ', $!font-size );
    has Numeric $.width;
    has Numeric $.height;
    has @.lines;
    has @.overflow is rw;
    has Str $.align where 'left'|'center'|'right'|'justify' = 'left';
    has Str $.valign where 'top'|'center'|'bottom' = 'top';
    has ParagraphTags $.type = Paragraph;
    has @.replaced;
    has Str $.text;

    # current graphics state
    has Numeric $.WordSpacing = 0;
    has Numeric $.CharSpacing = 0;
    has Numeric $.TextLeading = 0;
    has Numeric @.TextMatrix = [1, 0, 0, 1, 0, 0];
    subset Percentage of Numeric where * > 0;
    has Percentage $.HorizScaling = 100;

    method sync-graphics(:$!WordSpacing, :$!HorizScaling, :$!CharSpacing, :@!TextMatrix, :$!TextLeading) { }
    method !text-rise {
        given $!baseline {
            when 'alphabetic'  { 0 }
            when 'top'         { $!font.height( $!font-size, :from-baseline); }
            when 'bottom'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size) }
            when 'middle'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size)/2 }
            when 'ideographic' { $!font.height( $!font-size, :from-baseline) - $!font-size; }
            when 'hanging'     { $!font.height( $!font-size, :from-baseline, :hanging) }
        }

    }
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

    multi submethod TWEAK(:@chunks!, Bool :$kern = False) is default {

        my @atoms = @chunks; # copy
        my @line-atoms;
        my Bool $follows-ws = False;
        my $word-gap = self!word-gap;
        $!text //= @atoms.map(*.Str).join;

        my PDF::Content::Text::Line $line .= new: :$word-gap, :$!leading;
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
                        ($word, $word-width) = $!font.kern($atom);
                    }
                    else {
                        $word = [ $atom, ];
                        $word-width = $!font.stringwidth($atom);
                    }
                    $word-width *= $!font-size * $!HorizScaling / 100000;
                    $word-width += ($atom.chars - 1) * $!CharSpacing
                        if $!CharSpacing > -$!font-size;

                    for $word.list {
                        when Str {
                            $_ = $!font.encode($_).join;
                        }
                        when Numeric {
                            $_ = -$_;
                        }
                    }
                }
                when PDF::Content::Replaced {
                    $replacing = True;
                    $word = [-$atom.width * $!HorizScaling * 10 / $!font-size, ];
                    $word-width = $atom.width;
                }
            }

            if $!width && $line.words && $line.content-width + $pre-word-gap + $word-width > $!width {
                # line break
                $line = $line.new: :$word-gap, :$!leading;
                @!lines.push: $line;
                @line-atoms = [];
                $follows-ws = False;
                $pre-word-gap = 0;
            }
            if $replacing {
                my $leading = $atom.height * 1.1; # review this
                $line.leading = $leading
                    if $leading > $line.leading;
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
            if $!align eq 'justify';

        .align($!align, :$width )
            for @!lines;
    }

    sub flush-space(@words) returns Bool {
        my \flush = ? (@words && @words[0] ~~ /<Text::space>/);
        @words.shift if flush;
        flush;
    }

    #| calculates actual spacing between words
    method !word-gap returns Numeric {
        my $word-gap = $!space-width + $!WordSpacing + $!CharSpacing;
        $word-gap *= $!HorizScaling / 100
            unless $!HorizScaling =~= 100;
        $word-gap;
    }

    #| calculates WordSpacing needed to achieve a given word-gap
    method !word-spacing($word-gap is copy) returns Numeric {
        $word-gap /= $!HorizScaling / 100
            unless $!HorizScaling =~= 100;
        $word-gap - $!space-width - $!CharSpacing;
    }

    method width  { $!width //= self.content-width }
    method height { $!height //= self.content-height }
    method !dy {
        given $!valign {
            when 'center' { 0.5 }
            when 'bottom' { 1.0 }
            default       { 0 }
        };
    }
    method top-offset {
        self!dy * ($.height - $.content-height);
    }

    method align($!align) {
        .align($!align)
            for self.lines;
    }

    method content(Bool :$nl,   # add trailing line 
                   Bool :$top,  # position from top
                   Bool :$left, # position from left;
                  ) {

        my @content;
	my $space-size = -(1000 * $!space-width / $!font-size).round.Int;

        my $y-shift = $top ?? - $.top-offset !! self!dy * $.height;
        $y-shift -= self!text-rise;
        @content.push( OpCode::TextMove => [0, $y-shift ] )
            unless $y-shift =~= 0.0;

        my $dx = do given $!align {
            when 'center' { 0.5 }
            when 'right'  { 1.0 }
            default       { 0.0 }
        }
        my $x-shift = $left ?? $dx * $.width !! 0.0;
        # compute text positions of replaced content
        for @!replaced {
            my @Tm = @!TextMatrix;
            @Tm[4] += $x-shift + .<Tx>;
            @Tm[5] += $y-shift + .<Ty>;
            .<Tm> = @Tm;
        }

        my $word-spacing = $!WordSpacing;

        for @!lines -> \line {
            with self!word-spacing(line.word-gap) {
                @content.push( OpCode::SetWordSpacing => [ $word-spacing = $_ ])
                    unless $_ =~= $word-spacing || +line.words <= 1;
            }
            my $lead =  ($nl || +@!lines > 1)
                     && (!$!TextLeading.defined || $!TextLeading !=~= line.leading);
            @content.push: ( OpCode::SetTextLeading => [ $!TextLeading = line.leading ] )
                if $lead;
            @content.push: line.content(:$.font-size, :$x-shift);
            @content.push: OpCode::TextNextLine;
        }

        @content.pop
            if !$nl && @content;

        # restore original value
        @content.push( OpCode::SetWordSpacing => [ $!WordSpacing ])
            unless $!WordSpacing =~= $word-spacing;

        @content;
    }

}
