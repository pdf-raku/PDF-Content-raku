use v6;
use PDF::Graphics::Ops :OpNames;

class PDF::Graphics:ver<0.0.2>
    does PDF::Graphics::Ops {

    use PDF::DAO;
    use PDF::DAO::Stream;
    use PDF::Graphics::Image;

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
        PDF::Graphics::Image.open( $spec );
    }

    method inline-images {
	my PDF::DAO::Stream @images;
	for $.ops.keys -> $i {
	    my $v = $.ops[$i];
	    next unless $v.key eq 'BI';

	    my %dict = :Type( :name<XObject> ), :Subtype( :name<Image> ), PDF::Graphics::Image.inline-to-xobject($v.value[0]<dict>);
	    my $v1 = $.ops[$i+1];
	    die "BI not followed by ID image in content stream"
		unless $v1 && $v1.key eq 'ID';
	    my $encoded = $v1.value[0]<encoded>;

	    @images.push: PDF::DAO.coerce( :stream{ :%dict, :$encoded } );
	}
	@images;
    }

    use PDF::Graphics::Util::TransformMatrix;
    method transform( |c ) {
	my Numeric @matrix = PDF::Graphics::Util::TransformMatrix::transform-matrix( |c );
	$.ConcatMatrix( @matrix );
    }

    method text-transform( |c ) {
	my Numeric @matrix = PDF::Graphics::Util::TransformMatrix::transform-matrix( |c );
	$.SetTextMatrix( @matrix );
    }

    my subset Vector of List where {.elems == 2 && .[0] ~~ Numeric && .[1] ~~ Numeric}
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
              Str     :$key!,
              Numeric :$width is copy,
              Numeric :$height is copy,
              Align   :$align  = 'left',
              Valign  :$valign = 'bottom',
              Bool    :$inline = False,
        )  {

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
		# serialize the image to the content stream, aka: :BI[:$dict], :ID[:$stream], :EI[]
		$.ops( $obj.content(:inline) );
	    }
	    else {
		$.op(XObject, $key);
	    }
        };
    }

}
