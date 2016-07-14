use v6;
use PDF::Content::Ops :OpNames, :GraphicsContext, :ExtGState;

role PDF::Content:ver<0.0.5>
    does PDF::Content::Ops {

    use PDF::DAO;
    use PDF::DAO::Stream;
    use PDF::Content::Image;
    use PDF::Content::Text::Block;
    use PDF::Content::Font;

    has $.parent;

    method set-graphics($gs = PDF::DAO.coerce({ :Type{ :name<ExtGState> } }),
			Numeric :$opacity,
			Numeric :$transparency is copy,
			*%settings,
	) {

	my constant %Entries = %( ExtGState.enums.invert );

	with $opacity {
	    $transparency = 1 - $_
        }

	with $transparency {
	    %settings<fill-alpha> //= $_;
	    %settings<stroke-alpha> //= $_;
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

	my $gs-entry = self.parent.resource-key($gs, :eqv);
	self.SetGraphicsState($gs-entry);
    }

    method block( &do-stuff! ) {
        $.op(Save);
        &do-stuff(self);
        $.op(Restore);
    }

    method text( &do-stuff! ) {
        $.op(BeginText);
        &do-stuff(self);
        $.op(EndText);
    }

    method load-image(Str $spec ) {
        PDF::Content::Image.open( $spec );
    }

    #| extract any inline images from the content stream. returns an array of XObject Images
    method inline-images returns Array {
	my PDF::DAO::Stream @images;
	for $.ops.keys -> $i {
	    my $v = $.ops[$i];
	    next unless $v.key eq 'BI';

	    my %dict = ( :Type( :name<XObject> ), :Subtype( :name<Image> ),
			 PDF::Content::Image.inline-to-xobject($v.value[0]<dict>),
		);
	    my $v1 = $.ops[$i+1];
	    die "BI not followed by ID image in content stream"
		unless $v1 && $v1.key eq 'ID';
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
	my $gfx = self;
	my Numeric @tm = @$.TextMatrix;
	Proxy.new(
	    FETCH => method {
		@tm[4,5]
	    },
	    STORE => method (Vector $v) {
		@tm[4, 5] = @$v;
		$gfx.op(SetTextMatrix, @tm);
		@$v;
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

        my Str:D $key = $.parent.resource-key($obj),
        my Numeric $dx = { :left(0),   :center(-.5), :right(-1) }{$align};
        my Numeric $dy = { :bottom(0), :center(-.5), :top(-1)   }{$valign};

        given $obj<Subtype> {
            when 'Image' {
                if $width.defined {
                    $height //= $width * ($obj<Height> / $obj<Width>);
                }
                elsif $height.defined {
                    $width //= $height * ($obj<Width> / $obj<Height>);
                }
                else {
                    $width = $obj<Width>;
                    $height = $obj<Height>;
                }

                $dx *= $width;
                $dy *= $height;
            }
            when 'Form' {
                my Array $bbox = $obj<BBox>;
                my Numeric $obj-width = $bbox[2] - $bbox[0] || 1;
                my Numeric $obj-height = $bbox[3] - $bbox[1] || 1;

                if $width.defined {
                    $height //= $width * ($obj-height / $obj-width);
                }
                elsif $height.defined {
                    $width //= $height * ($obj-width / $obj-height);
                }
                else {
                    $width = $obj-width;
                    $height = $obj-height;
                }

                $dx *= $width;
                $dy *= $height;

                $width /= $obj-width;
                $height /= $obj-height;

            }
            default { die "xobject has missing or unknown Subtype: {$obj.perl}" }
        }

        self.block: {
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
		       :$font = self!current-font,
		       |c,  #| :$align, :$kern, :$line-height, :$width, :$height
        ) {
	# detect and use the current text-state font
	my Numeric $font-size = $.FontSize //= 16;
	my Numeric $word-spacing = $.WordSpacing;
	my Numeric $horiz-scaling = $.HorizScaling;
	my Numeric $char-spacing = $.CharSpacing;

        my PDF::Content::Text::Block $text-block .= new( :$text, :$font, :$font-size,
						         :$word-spacing, :$horiz-scaling, :$char-spacing,
						         |c );

	$.print( $text-block, |c)
	    unless $stage;

	$text-block;
    }

    multi method print(PDF::Content::Text::Block $text-block,
		       :$position,
		       Bool :$nl = False,
	) {

        my UInt $font-size = $text-block.font-size;
        my $font = $.parent.use-font: $text-block.font;
	my $font-key = $.parent.resource-key($font);

	my Bool $in-text = $.context == GraphicsContext::Text;
	self.op(BeginText) unless $in-text;

	self.text-position = $_
	    with $position;

	self.op(SetFont, $font-key, $font-size)
	    unless $.FontKey
	    && $font-key eq $.FontKey
	    && $font-size == $.FontSize;

	self.ops( $text-block.content(:$nl) );

	self.op(EndText) unless $in-text;

        $text-block;
    }

    #! output text move the  text position down one line
    method say($text, |c) {
        $.print($text, :nl, |c);
    }

    #| thin wrapper to $.op(SetFont, ...)
    multi method set-font( Hash $font!, Numeric $size = 16) {
        $.op(SetFont, $!parent.resource-key($font), $size);
    }
    multi method set-font( Str $font-key!, Numeric $size = 16) {
        $.op(SetFont, $font-key, $size);
    }

    method !current-font {
        with $.FontKey {
            $.parent.resource-entry('Font', $_)
        }
        else {
            $!parent.core-font('Courier');
        }
    }

    method font is rw returns List {
	my $obj = self;
	Proxy.new(
	    FETCH => method {
		($obj.FontKey, $obj.FontSize // 16);
	    },
	    STORE => method ($v) {
		my @v = $v.isa(List) ?? @$v !! [ $v, ];
		$obj.set-font(|@v);
		@v;
	    },
	    );
    }
    
    multi method print(Str $text, :$font = self!current-font, |c) {
        nextwith( $text, :$font, |c);
    }

}
