use v6;
use PDF::Content::Ops :OpCode, :GraphicsContext, :ExtGState;

role PDF::Content:ver<0.0.5>
    does PDF::Content::Ops {

    use PDF::DAO;
    use PDF::DAO::Stream;
    use PDF::Content::Image;
    use PDF::Content::Text::Block;
    use PDF::Content::Font;
    use PDF::Content::XObject;

    method set-graphics($gs = PDF::DAO.coerce({ :Type{ :name<ExtGState> } }),
			Numeric :$opacity is copy,
			Numeric :$transparency,
			*%settings,
	) {

	my constant %Entries = %( ExtGState.enums.invert );

	with $transparency {
	    $opacity = 1 - $_
        }

	with $opacity {
	    %settings<FillAlpha> //= $_;
	    %settings<StrokeAlpha> //= $_;
	}

	for %settings.keys.sort {
	    if $gs.can($_) {
		$gs."$_"() = %settings{$_}
	    }
	    elsif %Entries{$_}:exists {
		$gs{ $_ } = %settings{$_};
	    }
	    elsif ExtGState.enums{$_}:exists {
		$gs{ ExtGState.enums{$_} } = %settings{$_};
	    }
	    else {
		warn "ignoring graphics state option: $_";
	    }
	}

	my Str $gs-entry = self.resource-key($gs, :eqv);
	self.SetGraphicsState($gs-entry);
    }

    method graphics( &do-stuff! ) {
        $.op(Save);
        &do-stuff(self);
        $.op(Restore);
    }

    method text( &do-stuff! ) {
        $.op(BeginText);
        &do-stuff(self);
        $.op(EndText);
    }

    method canvas( &mark-up! ) {
        my $canvas = (require HTML::Canvas).new;
        $canvas.context(&mark-up);
        self.draw($canvas);
    }

    method load-image(Str $spec ) {
        PDF::Content::Image.open( $spec );
    }

    #| extract any inline images from the content stream. returns an array of XObject Images
    method inline-images returns Array {
	my PDF::DAO::Stream @images;
	for $.ops.keys.grep: { $.ops[$_].key eq 'BI' } -> $i {
	    my $v = $.ops[$i];
	    my $v1 = $.ops[$i+1];
	    die "'BI' op not followed by 'ID' in content stream"
		unless $v1 && $v1.key eq 'ID';

	    my %dict = ( :Type( :name<XObject> ), :Subtype( :name<Image> ),
			 PDF::Content::Image.inline-to-xobject($v.value[0]<dict>),
		);
	    my $encoded = $v1.value[0]<encoded>;

	    @images.push: PDF::DAO.coerce( :stream{ :%dict, :$encoded } );
	}
	@images;
    }

    use PDF::Content::Util::TransformMatrix;
    method transform( |c ) {
	my Numeric @matrix = PDF::Content::Util::TransformMatrix::transform-matrix( |c );
	$.ConcatMatrix( @matrix );
    }

    method text-transform( |c ) {
	my Numeric @matrix = PDF::Content::Util::TransformMatrix::transform-matrix( |c );
	$.SetTextMatrix( @matrix );
    }

    my subset Vector of List where {.elems == 2 && all(.[0], .[1]) ~~ Numeric}
    #| set the current text position on the page/form
    method text-position is rw returns Vector {
        warn '$.text-position accessor used outside of a text-block'
            unless $.context == GraphicsContext::Text;

	Proxy.new(
	    FETCH => sub (\p) {
	        $.TextMatrix[4, 5];
	    },
	    STORE => sub (\p, Vector \v) {
	        my Numeric @tm = @.TextMatrix;
                @tm[4] = $_ with v[0];
                @tm[5] = $_ with v[1];
		self.op(SetTextMatrix, @tm);
		v.list;
	    },
	    );
    }

    my subset Align of Str where 'left' | 'center' | 'right';
    my subset Valign of Str where 'top'  | 'center' | 'bottom';

    #| place an image, or form object
    method do(PDF::DAO::Stream $obj! where .<Type> eq 'XObject',
              Numeric $x = 0,
              Numeric $y = 0,
              Numeric :$width is copy,
              Numeric :$height is copy,
              Align   :$align  = 'left',
              Valign  :$valign = 'bottom',
              Bool    :$inline = False,
        )  {

        my Str:D $key = $.resource-key($obj),
        my Numeric $dx = { :left(0),   :center(-.5), :right(-1) }{$align};
        my Numeric $dy = { :bottom(0), :center(-.5), :top(-1)   }{$valign};

        $obj does PDF::Content::XObject[$obj<Subtype>]
            unless $obj ~~  PDF::Content::XObject;
        my $obj-width = $obj.width || 1;
        my $obj-height = $obj.height || 1;

        with $width {
            $height //= $_ * ($obj-height / $obj-width);
        }
        else {
            with $height {
                $width //= $_ * ($obj-width / $obj-height);
            }
            else {
                $width = $obj-width;
                $height = $obj-height;
            }
        }

        $dx *= $width;
        $dy *= $height;

        with $obj<Subtype> {
            when 'Form' {
                $width /= $obj-width;
                $height /= $obj-height;
            }
        }

        self.graphics: {
	    $.op(ConcatMatrix, $width, 0, 0, $height, $x + $dx, $y + $dy);
	    if $inline && $obj.Subtype eq 'Image' {
		# serialize the image to the content stream, aka: :BI[:$dict], :ID[:$encoded], :EI[]
		$.ops( $obj.inline-content );
	    }
	    else {
		$.op(XObject, $key);
	    }
        };
    }

    #! output text leave the text position at the end of the current line
    multi method print(Str $text,
		       Bool :$stage = False,
		       :$font = self!current-font[0],
		       |c,  #| :$align, :$kern, :$line-height, :$width, :$height, :$baseline
        ) {
	# detect and use the current text-state font
	my Numeric $font-size = $.font-size // self!current-font[1];

        my PDF::Content::Text::Block $text-block .= new(
            :$text, :$font, :$font-size,
	    :$.WordSpacing, :$.HorizScaling, :$.CharSpacing,
	    |c );

	$.print( $text-block, |c)
	    unless $stage;

	$text-block;
    }

    my subset XPos-Pair of Pair where {.key ~~ Align && .value ~~ Numeric}
    my subset YPos-Pair of Pair where {.key ~~ Valign && .value ~~ Numeric}
    my subset Text-Position of List where {
        .elems <= 2
        && (!defined(.[0]) || .[0] ~~ Numeric|XPos-Pair)
        && (!defined(.[1]) || .[1] ~~ Numeric|YPos-Pair)
    }

    multi method print(PDF::Content::Text::Block $text-block,
		       Text-Position :$position,
		       Bool :$nl = False,
	) {

        my Numeric \font-size = $text-block.font-size;
        my \font = $.use-font($text-block.font);
	my Bool \in-text = $.context == GraphicsContext::Text;

	self.op(BeginText) unless in-text;

        my Bool $left = False;
        my Bool $top = False;

	with $position {
            die "illegal text position: $_"
                unless $_ ~~ Text-Position;
            my $x;
            with $position[0] {
                when Numeric {$x = $_}
                when XPos-Pair {
                    my constant Dx = %( :left(0.0), :center(0.5), :right(1.0) );
                    $x = .value  +  Dx{.key} * $text-block.width;
                    $left = True; # position from left
                }
            }
            my $y;
            with $position[1] {
                when Numeric {$y = $_}
                when YPos-Pair {
                    my constant Dy = %( :top(0.0), :center(0.5), :bottom(1.0) );
                    $y = .value  -  Dy{.key} * $text-block.height;
                    $top = True; # position from top
                }
            }
                    
	    self.text-position = [$x, $y];
        }

        self.set-font(font, font-size);
        self."$_"() = $text-block."$_"()
            for <CharSpacing WordSpacing HorizScaling>;
	self.ops: $text-block.content(:$nl, :$top, :$left);

	self.op(EndText) unless in-text;

        $text-block;
    }

    #| output text; move the text position down one line
    method say($text, |c) {
        $.print($text, :nl, |c);
    }

    #| thin wrapper to $.op(SetFont, ...)
    multi method set-font( Hash $font!, Numeric $size = 16) {
        $.op(SetFont, $.resource-key($font), $size)
            if !$.font-face || $.font-size != $size || $.font-face !eqv $font;
    }

    method !current-font {
        $.Font // [$.core-font('Courier'), 16]
    }

    method font is rw returns Array {
	Proxy.new(
	    FETCH => sub (\p) {
		$.Font;
	    },
	    STORE => sub (\p, $v) {
		my @v = $v.isa(List) ?? @$v !! [ $v, ];
		self.set-font(|@v);
	    },
	    );
    }
    
    multi method print(Str $text, :$font = self!current-font[0], |c) {
        nextwith( $text, :$font, |c);
    }

    method draw($canvas) {
        my $renderer = (require HTML::Canvas::To::PDF).new: :gfx(self);

        $canvas.render($renderer);
    }

}
