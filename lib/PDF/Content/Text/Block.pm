use v6;

class PDF::Content::Text::Block {

    use PDF::Content::Text::Line;
    use PDF::Content::Ops :OpCode, :TextMode;

    has Str     $.text;
    has         $.font is required;
    has Numeric $.font-size = 16;
    has Numeric $.leading = $!font-size * 1.1;
    has Numeric $.font-height  = $!font.height( $!font-size );
    has Str     $.baseline = 'alphabetic';
    has Numeric $!space-width = $!font.stringwidth(' ', $!font-size );
    has Numeric $.WordSpacing = 0;
    has Numeric $.CharSpacing = 0;
    subset Percentage of Numeric where * > 0;
    has Percentage $.HorizScaling = 100;
    has Numeric $.width;
    has Numeric $.height;
    has @.lines;
    has @.overflow is rw;
    has Str $.align where 'left'|'center'|'right'|'justify' = 'left';
    has Str $.valign where 'top'|'center'|'bottom' = 'top';

    method !text-rise {
        given $!baseline.lc {
            when 'top'         { $!font.height( $!font-size, :from-baseline); }
            when 'bottom'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size) }
            when 'middle'      { $!font.height( $!font-size, :from-baseline) - $!font.height( $!font-size)/2 }
            when 'ideographic' { $!font.height( $!font-size, :from-baseline) - $!font-size; }
            when 'hanging'     { $!font.height( $!font-size, :from-baseline, :hanging) }
            when 'alphabetic'  { 0 }
            default { warn "unhandled baseline: $_"; }
        }

    }
    method content-width  { @!lines.map( *.content-width ).max }
    method content-height { max( (+@!lines - 1) * $!leading  +  $!font-height, 0) }

    grammar Text {
        token nbsp  { <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> }
        token space { [\s <!after <nbsp> >]+ }
        token word  { [ <![ - ]> <!before <space>> . ]+ '-'? | '-' }
    }

    multi submethod TWEAK(Str :$!text!, |c) {
        my Str @chunks = $!text.comb(/<Text::word> | <Text::space>/);
        self.TWEAK( :@chunks, |c );
    }

    sub flush-space(@words) returns Bool {
        my \flush = ? (@words && @words[0] ~~ /<Text::space>/);
        @words.shift if flush;
        flush;
    }

    #| calculates actual spacing between words
    method !word-gap {
        my $word-gap = $!space-width + $!WordSpacing + $!CharSpacing;
        $word-gap *= $!HorizScaling / 100
            if $!HorizScaling != 100;
        $word-gap;
    }

    #| calculates WordSpacing needed to achieve a given word-gap
    method !word-spacing($word-gap is copy) {
        $word-gap /= $!HorizScaling / 100
            if $!HorizScaling != 100;
        $word-gap - $!space-width - $!CharSpacing;
    }

    multi submethod TWEAK(Str :@chunks!, Bool :$kern = False) is default {

        $!text //= @chunks.join;
        my Bool $follows-ws = False;
        my $word-gap = self!word-gap;

        my PDF::Content::Text::Line $line .= new: :$word-gap;
        @!lines.push: $line;

        flush-space(@chunks);
  
        while @chunks {
            my Str $text = @chunks.shift;

            my $word;
	    my $word-width;

            if ($kern) {
                ($word, $word-width) = $!font.kern($text);
            }
            else {
                $word = [ $text, ];
                $word-width = $!font.stringwidth($text);
            }
            $word-width *= $!font-size * $!HorizScaling / 100000;
            $word-width += ($text.chars - 1) * $!CharSpacing
                if $!CharSpacing > -$!font-size;

            for $word.list {
                when Str {
                    $_ = $!font.encode($_).join;
                }
                when Numeric {
                    $_ = - $_;
                }
            }

            if $!width && $line.words && $line.content-width + $word-gap + $word-width > $!width {
                # line break
                if $!height && self.content-height + $!leading > $!height {
                    # height exceeded
                    @!overflow.push: $text;
                    last;
                }
                else {
                    $line = $line.new( :$word-gap );
                    @!lines.push: $line ;
                }
                $follows-ws = False;
            }

            $line.word-boundary[+$line.words] = $follows-ws;
            $line.words.push: $word;
            $line.word-width += $word-width;

            $follows-ws = flush-space(@chunks);
        }

        @!overflow.append: @chunks;

        my $width = $!width // self.content-width
            if $!align eq 'justify';

        .align($!align, :$width )
            for @!lines;
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
        @content.push: ( OpCode::SetTextLeading => [ $!leading ] )
            if $nl || +@!lines > 1;

	my $space-size = -(1000 * $!space-width / $!font-size).round.Int;

        {
            my $y-shift = $top ?? - $.top-offset !! self!dy * $.height;
            $y-shift -= self!text-rise;
            @content.push( OpCode::TextMove => [0, $y-shift ] )
                unless $y-shift =~= 0.0;
        }

        my $dx = do given $!align {
            when 'center' { 0.5 }
            when 'right'  { 1.0 }
            default       { 0 }
        }
        my $x-shift = $left ?? $dx * $.width !! 0;

        my $word-spacing = $!WordSpacing;

        for @!lines -> \line {
            with self!word-spacing(line.word-gap) {
                @content.push( OpCode::SetWordSpacing => [ $word-spacing = $_ ])
                    unless $_ =~= $word-spacing || +line.words <= 1;
            }
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
