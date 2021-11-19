use v6;

#| simple plain-text blocks
class PDF::Content::Text::Box {

    use PDF::Content::Text::Style;
    use PDF::Content::Text::Line;
    use PDF::Content::Ops :OpCode, :TextMode;
    use PDF::Content::XObject;

    has Numeric $.width;
    has Numeric $.height;
    has Numeric $.indent = 0;
    my subset Alignment of Str is export(:Alignment) where 'left'|'center'|'right'|'justify';
    has Alignment $.align = 'left';
    my subset VerticalAlignment of Str is export(:VerticalAlignment) where 'top'|'center'|'bottom';
    has VerticalAlignment $.valign = 'top';
    has PDF::Content::Text::Style $.style is built is rw handles <font font-size leading kern WordSpacing CharSpacing HorizScaling TextRender TextRise baseline-shift space-width>;
    has PDF::Content::Text::Line @.lines;
    has @.overflow is rw;
    has @.images;
    has Str $.text;
    has Bool $!squish;
    has Bool $.verbatum;

    method content-width  { @!lines».content-width.max }
    method content-height {
        @!lines».height.sum * $.leading;
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

    multi submethod TWEAK(:@chunks!, :$!squish = False, |c) is default {
        $!style .= new(|c);
        $!text = @chunks».Str.join;
	self!layup(@chunks);
    }

    method !layup(@atoms is copy) is default {
        my @line-atoms;
        my UInt $preceding-spaces = self!flush-spaces(@atoms);
        my $word-gap = self!word-gap;
	my $height = $!style.font-size;

        my PDF::Content::Text::Line $line .= new: :$word-gap, :$height, :$!indent;
	@!lines = [ $line ];

        while @atoms {
            my subset StrOrImage where Str | PDF::Content::XObject;
            my StrOrImage $atom = @atoms.shift;
            my Bool $reserving = False;
            my $line-breaks = 0;
            my List() $word;
	    my $word-width;
            my $word-pad = $preceding-spaces * $word-gap;

            given $atom {
                when Str {
                    if $!verbatum && +.match("\n", :g) -> $n {
                        $line-breaks = $n;
                        $word = [ ' ' x $preceding-spaces ];
                        $word-width = $word-pad;
                    }
                    elsif $!style.kern {
                        given $!style.font.kern($atom) {
                            $word = .[0].list.map: {
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
                    $reserving = True;
                    $word = [-$atom.width * $.HorizScaling * 10 / $!style.font-size, ];
                    $word-width = $atom.width;
                }
            }

            $line-breaks ||= ($line.words || $line.indent) && $line.content-width + $word-pad + $word-width > $!width
                if $!width;

            while $line-breaks--  {
                $line = $line.new: :$word-gap, :$height;
                @!lines.push: $line;
                @line-atoms = [];
                $preceding-spaces = 0;
                $word-pad = 0;
            }
            if $reserving {
                given $atom.height {
                    $line.height = $_
                        if $_ > $line.height;
                }
            }
            if $!height && self.content-height > $!height {
                # height exceeded
                @!lines.pop if @!lines;
                @!overflow.append: @line-atoms;
                last;
            }

            if $reserving {
                my $Tx = $line.content-width + $word-pad;
                my $Ty = @!lines
                    ?? @!lines[0].height * $.leading  -  self.content-height
                    !! 0.0;
                @!images.push( { :$Tx, :$Ty, :xobject($atom) } )
            }

            @line-atoms.push: $atom;
            $line.spaces[+$line.words] = $preceding-spaces;
            $line.words.push: $word;
            $line.word-width += $word-width;
	    $line.height = $height
		if $height > $line.height;

            $preceding-spaces = self!flush-spaces(@atoms);
        }

        @!overflow.append: @atoms;

    }

    method !flush-spaces(@words) returns UInt {
        my $n = 0; # space count for padding purposes
        if @words && @words[0] ~~ /<Text::space>/ {
            $n = @words[0].chars;
            if $!verbatum && (my $last-nl = @words[0].rindex("\n")).defined {
                # count spaces after last new-line
                $n -= $last-nl + 1;
                $n = 0 if $!squish;
            }
            else {
                @words.shift;
                $n = 1 if $!squish;
            }
        }
        $n;
    }

    #| calculates actual spacing between words
    method !word-gap returns Numeric {
        my $word-gap = $.space-width + $.WordSpacing + $.CharSpacing;
        $word-gap * $.HorizScaling / 100;
    }

    method width  { $!width  // self.content-width }
    method height { $!height // self.content-height }
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
        @content.push: 'comment' => 'text: ' ~ @!lines».words.map(*.grep(Str).Slip).join: ' '
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
		    if $leading !=~= lead;
		@content.push: OpCode::TextNextLine;
	    }

            my $space-pad = scale * (line.word-gap - self.space-width);
            @content.push: line.content(:$.font, :$.font-size, :$x-shift, :$space-pad);
        }

	if $nl {
	    my $height = @!lines ?? @!lines.tail.height !! $.font-size;
	    @content.push: ( OpCode::SetTextLeading => [ $leading = $height * $.leading ] )
                unless $.font-size * $.leading =~= $leading;
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
            $gfx.ConcatMatrix(|.<Tm>);
            .<xobject>.finish;
            $gfx.XObject($gfx.resource-key(.<xobject>));
            $gfx.Restore;
        }
    }

}
