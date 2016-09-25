use v6;

class PDF::Content::Text::Block {

    use PDF::Content::Text::Line;
    use PDF::Content::Ops :OpNames, :TextMode;

    has Str $.text;
    has Numeric $.font-size is required;
    has         $.font is required;
    has Numeric $.font-height;
    has Numeric $.font-base-height = $!font.height( $!font-size, :from-baseline );
    has Numeric $.line-height;
    has Numeric $!space-width;
    has Numeric $!word-spacing;
    subset Percentage of Numeric where * > 0;
    has Percentage $.horiz-scaling = 100;
    has Numeric $!width;
    has Numeric $!height;
    has @.lines;
    has @.overflow is rw;
    has Str $!align where 'left'|'center'|'right'|'justify';
    has Str $.valign where 'top'|'center'|'bottom'|'text';

    method actual-width  { @!lines.map( *.actual-width ).max }
    method actual-height { (+@!lines - 1) * $!line-height  +  $!font-height }

    grammar Text {
        token nbsp  { <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> }
        token space { [\s <!after <nbsp> >]+ }
        token word  { [ <![ - ]> [<!before \s> . | <nbsp>] ]+ '-'? }
    }

    multi submethod BUILD(Str :$!text!, |c) {
        my Str @chunks = $!text.comb(/<Text::word> | <Text::space>/);
        self.BUILD( :@chunks, |c );
    }

    sub flush-space(@words) returns Bool {
        if @words && @words[0] ~~ /<Text::space>/ {
            @words.shift;
            True
        } else {
            False
        }
    }

    multi submethod BUILD(Str  :@chunks!,
                               :$!font!,
			  Numeric :$!font-size = 16,
                          Numeric :$!line-height = $!font-size * 1.1,
			  Numeric :$!horiz-scaling = 100,
                          Numeric :$char-spacing = 0,
                          Numeric :$!word-spacing = 0,
                          Numeric :$!width?,        #| optional constraint
                          Numeric :$!height?,       #| optional constraint
                          Str :$!align = 'left',
                          Str :$!valign = 'text',
                          Bool :$kern = False,
        ) is default {

        $!text //= @chunks.join;
	$!space-width = $!font.stringwidth(' ', $!font-size );
        $!font-height = $!font.height( $!font-size );
        my Bool $follows-ws = False;
        my $word-spacing = $!space-width + $!word-spacing;
        $word-spacing *= $!horiz-scaling / 100
            if $!horiz-scaling != 100;
        my PDF::Content::Text::Line $line .= new: :$word-spacing;
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
            $word-width *= $!font-size * $!horiz-scaling / 100000;
            $word-width *= ($text.chars - 1) * $char-spacing
                if $char-spacing > 0;

            for $word.list {
                when Str {
                    $_ = $!font.encode($_).join;
                }
                when Numeric {
                    $_ = - $_;
                }
            }

            if $!width && $line.words && $line.actual-width + $word-spacing + $word-width > $!width {
                # line break
                if $!height && self.actual-height + $!line-height > $!height {
                    # height exceeded
                    @!overflow.push: $text;
                    last;
                }
                else {
                    $line = $line.new( :$word-spacing );
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

        my $width = $!width // self.actual-width
            if $!align eq 'justify';

        .align($!align, :$width )
            for @!lines;
    }

    method width  { $!width //= self.actual-width }
    method height { $!height //= self.actual-height }
    method !dy {
        given $!valign {
            when 'center' { 0.5 }
            when 'bottom' { 1.0 }
            default       { 0 }
        };
    }
    method top-offset {
        self!dy * ($.height - $.actual-height);
    }

    method align($!align) {
        .align($!align)
            for self.lines;
    }

    method content(Bool :$nl,   # add trailing line 
                   Bool :$top,  # position from top
                   Bool :$left, # position from left;
                  ) {

        my @content = ( OpNames::SetTextLeading => [ $!line-height ], )
	    if $nl || +@!lines > 1;

	my $space-size = -(1000 * $!space-width / $!font-size).round.Int;

        if $!valign ne 'text' {
            # adopt html style text positioning. from the top of the font, not the baseline.
            my $y-shift = $top ?? - $.top-offset !! self!dy * $.height;
            @content.push( OpNames::TextMove => [0, $y-shift - $!font-base-height ] );
        }

        my $dx = do given $!align {
            when 'center' { 0.5 }
            when 'right'  { 1.0 }
            default       { 0 }
        }
        my $x-shift = $left ?? $dx * $.width !! 0;

        for @!lines {
            with .word-spacing - $!space-width {
                @content.push( OpNames::SetWordSpacing => [ $!word-spacing = $_ ])
                    unless $_ =~= $!word-spacing || +.words <= 1;
            }
            @content.push: .content(:$.font-size, :$space-size, :$x-shift);
            @content.push: OpNames::TextNextLine;
        }

        @content.pop
            if !$nl && @content;

        @content;
    }

}
