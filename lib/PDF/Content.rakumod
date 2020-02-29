use v6;
use PDF::Content::Ops :OpCode, :GraphicsContext, :ExtGState;

class PDF::Content:ver<0.4.2>
    is PDF::Content::Ops {

    use PDF::COS;
    use PDF::COS::Stream;
    use PDF::Content::Text::Block;
    use PDF::Content::XObject;
    use PDF::Content::Tag :ParagraphTags;
    use PDF::Content::Tag::Object;

    my subset Align of Str where 'left' | 'center' | 'right';
    my subset Valign of Str where 'top'  | 'center' | 'bottom';
    my subset XPos-Pair of Pair where {.key ~~ Align && .value ~~ Numeric}
    my subset YPos-Pair of Pair where {.key ~~ Valign && .value ~~ Numeric}
    my subset Position of List where {
        .elems <= 2
        && .[0] ~~ Numeric|XPos-Pair|Any:U
        && .[1] ~~ Numeric|YPos-Pair|Any:U
    }

    method graphics( &meth! ) {
        $.op(Save);
        my \rv = meth(self);
        $.op(Restore);
        rv;
    }

    method text( &meth! ) {
        $.op(BeginText);
        my \rv = meth(self);
        $.op(EndText);
        rv;
    }

    method marked-content($tag, &code, :$props) is DEPRECATED<tag> {
        with $props { $.tag($tag, &code, |$_) } else { $.tag($tag, &code) }
    }

    method !get-mcid(%props) {
        $.parent.use-mcid($_)
            with %props<MCID>;
    }

    method op-dict(PDF::Content::Tag $tag) {
        my Pair $op := self.ops[$tag.start-1];
        # upgrade BMC operator to BDC to accomodate dict
        $op = BDC => $op.value
            if $op.key eq 'BMC';
        $op.value[1]<dict> //= %();
    }

    method set-mcid(PDF::Content::Tag $tag) {
        $tag.mcid //= do {
            # edit opening BDC or BMC op in op-tree
            my UInt $int = $.parent.next-mcid;
            self.op-dict($tag)<MCID> = :$int;
            $int;
        }
    }

    multi method tag(PDF::Content::Tag $_, &meth) {
        samewith( .tag, |.attributes, &meth);
    }

    multi method tag(PDF::Content::Tag $_) {
        samewith( .tag, |.attributes);
    }

    multi method tag(Str $tag, *%props) {
        self!get-mcid: %props;

        my \rv := %props
            ?? $.MarkPointDict($tag, $%props)
            !! $.MarkPoint($tag);
        $.closed-tag;
    }

    multi method tag(Str $tag, &meth!, *%props) {
        self!get-mcid: %props;

        %props
            ?? $.BeginMarkedContentDict($tag, $%props)
            !! $.BeginMarkedContent($tag);

        my \rv := meth(self);
        $.EndMarkedContent;
        rv;
    }

    multi method tag(Str $name, Hash $object, *%attributes) {
        self.add-tag: :!strict, PDF::Content::Tag::Object.new: :$name, :$.owner, :$object, :%attributes;
    }

    # to allow e.g. $gfx.tag.Header({ ... });
    my class Tagger {
        use PDF::Content::Tag :TagSet, :%TagAliases;
        has $.gfx is required;
        method FALLBACK($tag, |c) {
            $!gfx.tag($tag, |c)
        }
    }
    has Tagger $!tagger;
    multi method tag is default {
        $!tagger //= Tagger.new: :gfx(self);
    }

    method canvas( &mark-up! ) {
        my $canvas := (require HTML::Canvas).new;
        $canvas.context(&mark-up);
        self.draw($canvas);
    }

    method load-image($spec) {
        PDF::Content::XObject.open($spec);
    }

    #| extract any inline images from the content stream. returns an array of XObject Images
    method inline-images returns Array {
	my PDF::COS::Stream @images;
	for $.ops.keys.grep: { $.ops[$_].key eq 'BI' } -> $i {
	    my $bi = $.ops[$i];
	    my $id = $.ops[$i+1];
	    die "'BI' op not followed by 'ID' in content stream"
		unless $id ~~ Pair && $id.key eq 'ID';

	    my %dict = PDF::Content::XObject['Image'].inline-to-xobject($bi.value[0]<dict>);
	    my $encoded = $id.value[0]<encoded>;

	    @images.push: PDF::COS.coerce( :stream{ :%dict, :$encoded } );
	}
	@images;
    }

    use PDF::Content::Matrix :transform;
    method transform( |c ) {
	my Numeric @matrix = transform( |c );
	$.ConcatMatrix( @matrix );
    }

    method text-transform( |c ) {
	my Numeric @matrix = transform( |c );
	$.SetTextMatrix( @matrix );
    }

    #| place an image, or form object
    multi method do(PDF::COS::Stream $obj! where .<Subtype> ~~ 'Image'|'Form',
              Position :$position = [0, 0],
              Numeric  :$width is copy,
              Numeric  :$height is copy,
              Align    :$align is copy  = 'left',
              Valign   :$valign is copy = 'bottom',
              Bool     :$inline = False,
              Str      :$tag is copy,
        )  {

        my Numeric ($x, $y);
        given $position[0] {
            when XPos-Pair { $align = .key; $x = .value; }
            default        { $x = $_;}
        }
        given $position[1] {
            when YPos-Pair { $valign = .key; $y = .value; }
            default        { $y = $_;}
        }
        my Numeric $dx = { :left(0),   :center(-.5), :right(-1) }{$align};
        my Numeric $dy = { :bottom(0), :center(-.5), :top(-1)   }{$valign};

        $obj does PDF::Content::XObject[$obj<Subtype>]
            unless $obj ~~ PDF::Content::XObject;
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

        if $obj<Subtype> ~~ 'Form' {
            $obj.finish;
            $width /= $obj-width;
            $height /= $obj-height;
        }

        $tag //= 'Img' unless self.open-tags;

        with $tag {
            self!get-mcid(my %props);
            %props
                ?? $.BeginMarkedContentDict($tag, $%props)
                !! $.BeginMarkedContent($tag)
        }

        self.graphics: {
            $.op(ConcatMatrix, $width, 0, 0, $height, $x + $dx, $y + $dy);
            if $inline && $obj<Subtype> ~~ 'Image' {
                # serialize the image to the content stream, aka: :BI[:$dict], :ID[:$encoded], :EI[]
                $.ops( $obj.inline-content );
            }
            else {
                my Str:D $key = $.resource-key($obj),
                $.op(XObject, $key);
            }
        }

        self.EndMarkedContent() with $tag;

        # return the display rectangle for the image
        my \x0 = $x + $dx;
        my \y0 = $y + $dy;
        (x0, y0, x0 + $width, y0 + $height);
    }
    multi method do($img, Numeric $x, Numeric $y = 0, *%opt) is default {
        self.do($img, :position[$x, $y], |%opt);
    }

    my subset Pattern of Hash where .<PatternType> ~~ 1|2;
    my subset TilingPattern of Pattern where .<PatternType> == 1;
    method use-pattern(Pattern $pat!) {
        $pat.finish
            if $pat ~~ TilingPattern;
        :Pattern(self.resource-key($pat));
    }

    multi method paint(Bool :$fill! where .so, Bool :$even-odd,
                       Bool :$close, Bool :$stroke) {
        my @paint-ops = do {
            when $even-odd {
                when $close { $stroke ?? <CloseEOFillStroke> !! <Close EOFill> }
                default     { $stroke ?? <EOFillStroke>      !! <EOFill>       }
            }
            default {
                when $close { $stroke ?? <CloseFillStroke>   !! <Close Fill>   }
                default     { $stroke ?? <FillStroke>        !! <Fill>         }
            }
        }
                    
        self."$_"()
            for @paint-ops;
    }

    multi method paint(Bool :$stroke! where .so, Bool :$close) {
        $close ?? self.CloseStroke !! self.Stroke
    }

    multi method paint() is default {
        self.EndPath;
    }

    method text-block($font = self!current-font[0], |c) {
        # detect and use the current text-state font
        my Numeric $font-size = $.font-size // self!current-font[1];
        PDF::Content::Text::Block.new(
            :gfx(self), :$font, :$font-size,
            |c,
            );
    }

    #| output text leave the text position at the end of the current line
    multi method print(Str $text,
                       |c,  # :$align, :$valign, :$kern, :$leading, :$width, :$height, :$baseline-shift, :$font, :$font-size
        ) {

        my $text-block = self.text-block( :$text, |c);
        @.print( $text-block, |c);
    }

    method !set-position($text-block, $position,
                         Bool :$left! is rw,
                         Bool :$top! is rw) {
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

    my subset Vector of List where {.elems == 2 && all(.list) ~~ Numeric}
    method text-position is rw returns Vector {
        warn '$.text-position accessor used outside of a text-block'
            unless $.context == GraphicsContext::Text;

	Proxy.new(
	    FETCH => {
                my @tm = @.TextMatrix;
	        @tm[4] / @tm[0], @tm[5] / @tm[3];
	    },
	    STORE => -> $, Vector \v {
                my @tm = @.TextMatrix;
                @tm[4] = $_ * @tm[0] with v[0];
                @tm[5] = $_ * @tm[3] with v[1];
		self.op(SetTextMatrix, @tm);
	    },
	);
    }

    method set-tag-bbox(@rect) {
        # locate the opening marked content dict in the op-tree
        my $tag-obj = self.closed-tag;
        my @bbox = self.base-coords(@rect);
        $tag-obj.attributes<BBox> = @bbox;
        $.op-dict($tag-obj)<BBox> = :array[ @bbox.map( -> $real { :$real }) ];
    }

    multi method print(PDF::Content::Text::Block $text-block,
                       Position :$position,
                       Bool :$nl = False,
                       Bool :$preserve = True,
                       Str :$tag is copy,
        ) {

        my Bool $left = False;
        my Bool $top = False;
        my Bool \in-text = $.context == GraphicsContext::Text;

        $tag //= 'P' unless self.open-tags;

        with $tag {
            self!get-mcid(my %atts);
            %atts
                ?? self.BeginMarkedContentDict($_, $%atts)
                !! self.BeginMarkedContent($_)
        }

        self.BeginText unless in-text;

        self!set-position($text-block, $_, :$left, :$top)
            with $position;
        my ($x, $y) = $.text-position;
        my ($dx, $dy) = $text-block.render(self, :$nl, :$top, :$left, :$preserve);

        self.EndText() unless in-text;
        self.EndMarkedContent() with $tag;

        my \x0 = $x + $dx;
        my \y0 = $y + $dy;
        my \x1 = x0 + $text-block.width;
        my \y1 = y0 + $text-block.height;

        (x0, y0, x1, y1);
    }

    #| output text; move the text position down one line
    method say($text = '', |c) {
        @.print($text, :nl, |c);
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
            FETCH => {
                $.Font;
            },
            STORE => -> $, $v {
                my @v = $v.isa(List) ?? @$v !! $v;
                @v[0] = .use-font(@v[0]) with $.parent;
                self.set-font(|@v);
            },
        );
    }

    multi method print(Str $text, :$font = self!current-font[0], |c) {
        nextwith( $text, :$font, |c);
    }

    method draw($canvas, :$renderer = (require HTML::Canvas::To::PDF).new: :gfx(self)) {
        $canvas.render($renderer);
    }

    # map transformed user coordinates to untransformed (default) coordinates
    use PDF::Content::Matrix :dot;
    method base-coords(*@coords where .elems %% 2, :$user = True, :$text = !$user) {
        (
            flat @coords.map: -> $x is copy, $y is copy {
                ($x, $y) = dot($.TextMatrix, $x, $y) if $text;
                ($x, $y) = dot($.CTM, $x, $y) if $user;
                $x, $y;
            }
        )
    }
    method user-default-coords(|c) is DEPRECATED('base-coords') {
        $.base-coords(|c);
    }
}
