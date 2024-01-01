#| PDF Content construction and manipulation
class PDF::Content:ver<0.7.3> {

    use PDF::Content::Ops :OpCode, :GraphicsContext, :ExtGState;
    also is PDF::Content::Ops;

=begin pod

=head2 Description

implements a PDF graphics state machine for composition, or rendering:

=head2 Synposis

=begin code :lang<raku>
use lib 't';
use PDF::Content;
use PDF::Content::Canvas;
use PDFTiny;
my PDFTiny $pdf .= new;
my PDF::Content::Canvas $canvas = $pdf.add-page;
my PDF::Content $gfx .= new: :$canvas;
$gfx.use-font: $pdf.core-font('Courier'); # define /F1 font
$gfx.BeginText;
$gfx.Font = 'F1', 16;
$gfx.TextMove(10, 20);
$gfx.ShowText('Hello World');
$gfx.EndText;
say $gfx.Str;
# BT
#  /F1 16 Tf
#  10 20 Td
#  (Hello World) Tj
# ET
=end code

=head2 Methods

=end pod

    use PDF::COS;
    use PDF::COS::Stream;
    use PDF::Content::Text::Box;
    use PDF::Content::Text::Block; # deprecated
    use PDF::Content::XObject;
    use PDF::Content::Tag :ParagraphTags;
    use PDF::Content::Font;
    use PDF::Content::Font::CoreFont;
    use PDF::Content::FontObj;
    use are;

    has Str $.actual-text is rw;

    my subset Align of Str where 'left' | 'center' | 'right';
    my subset Valign of Str where 'top'  | 'center' | 'bottom';
    my subset XPos-Pair of Pair where {.key ~~ Align && .value ~~ Numeric}
    my subset YPos-Pair of Pair where {.key ~~ Valign && .value ~~ Numeric}
    my subset Position of List where { .elems <= 2 }
    my subset Vector of Position  where { .&are ~~ Numeric }

    #| Add a graphics block
    method graphics( &meth! ) {
        $.op(Save);
        my \rv = self.&meth();
        $.op(Restore);
        rv;
    }

    #| Add a text block
    method text( &meth! ) {
        $.op(BeginText);
        my \rv = self.&meth();
        $.op(EndText);
        return rv;
    }

    method marked-content($tag, &code, :$props) is DEPRECATED<mark> {
        with $props { $.tag($tag, &code, |$_) } else { $.tag($tag, &code) }
    }

    method !setup-mcid(Bool :$mark, :%props) {
        with %props<MCID> {
            $.canvas.use-mcid($_);
        }
        elsif $mark {
            die "illegal nesting of marked content tags"
                if self.open-tags.first(*.mcid.defined);
            %props<MCID> = $.canvas.next-mcid()
        }
    }

    #| Add a marked content block
    method mark(Str $t, &meth, |c --> PDF::Content::Tag) { self.tag($t, &meth, :mark, |c) }

    multi method tag(PDF::Content::Tag $_, &meth) {
        samewith( .tag, &meth, |.attributes, );
    }

    multi method tag(PDF::Content::Tag $_) {
        samewith( .tag, |.attributes);
    }

    #| Add an empty content tag, optionally marked
    multi method tag(Str $tag, Bool :$mark, *%props --> PDF::Content::Tag) {
        self!setup-mcid: :$mark, :%props;
        %props
            ?? $.MarkPointDict($tag, $%props)
            !! $.MarkPoint($tag);
        $.closed-tag;
    }

    #| Add tagged content, optionally marked
    multi method tag(Str $tag, &meth!, Bool :$mark, *%props --> PDF::Content::Tag) {
        self!setup-mcid: :$mark, :%props;
        %props
            ?? $.BeginMarkedContentDict($tag, $%props)
            !! $.BeginMarkedContent($tag);
        self.&meth();
        $.EndMarkedContent;
        $.closed-tag;
    }

    # to allow e.g. $gfx.tag.Header({ ... });
    my class Tagger {
       use PDF::Content::Tag :TagSet, :%TagAliases;
        has $.gfx is required;
        method FALLBACK($tag, |c) {
            if $tag ∈ TagSet {
                $!gfx.tag($tag, |c)
            }
            else {
                with %TagAliases{$tag} {
                    $!gfx.tag($_, |c)
                }
                else {
                    die "unknown tag: $_";
                }
            }
        }
    }
    has Tagger $!tagger;
    multi method tag {
        $!tagger //= Tagger.new: :gfx(self);
    }

    #| Open an image from a file-spec or data-uri
    method load-image($spec --> PDF::Content::XObject) {
        PDF::Content::XObject.open($spec);
    }

    #| extract any inline images from the content stream. returns an array of XObject Images
    method inline-images returns Array[PDF::Content::XObject] {
        my PDF::Content::XObject @images;
        for $.ops.keys.grep: { $.ops[$_].key eq 'BI' } -> $i {
            my $bi = $.ops[$i];
            my $id = $.ops[$i+1];
            die "'BI' op not followed by 'ID' in content stream"
                unless $id ~~ Pair && $id.key eq 'ID';

            my %dict = PDF::Content::XObject['Image'].inline-to-xobject($bi.value[0]<dict>);
            my $encoded = $id.value[0]<encoded>;

            @images.push: PDF::COS::Stream.COERCE: { :%dict, :$encoded };
        }
        @images;
    }

    use PDF::Content::Matrix :transform;
    #| perform a series of graphics transforms
    method transform( |c ) {
        my Numeric @matrix = transform( |c );
        $.ConcatMatrix( @matrix );
    }

    #| perform a series of text transforms
    method text-transform( |c ) {
        my Numeric @matrix = transform( |c );
        $.SetTextMatrix( @matrix );
    }

    #| place an image, or form object
    multi method do(PDF::Content::XObject $obj!,
              Position :$position = [0, 0],
              Align    :$align is copy  = 'left',
              Valign   :$valign is copy = 'bottom',
              Numeric  :$width is copy,
              Numeric  :$height is copy,
              Bool     :$inline = False,
              --> List
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

        my \x0 = $x  +  $width  * { :left(0),   :center(-.5), :right(-1) }{$align};
        my \y0 = $y  +  $height * { :bottom(0), :center(-.5), :top(-1)   }{$valign};
        my \x1 = x0  +  $width;
        my \y1 = y0  +  $height;

        if $obj<Subtype> ~~ 'Form' {
            $obj.finish;
            $width /= $obj-width;
            $height /= $obj-height;
        }

        self.graphics: {
            $.op(ConcatMatrix, $width, 0, 0, $height, x0, y0);
            if $inline && $obj<Subtype> ~~ 'Image' {
                # serialize the image to the content stream, aka: :BI[:$dict], :ID[:$encoded], :EI[]
                $.ops( $obj.inline-content );
            }
            else {
                my Str:D $key = $.resource-key($obj),
                $.op(XObject, $key);
            }
        }

        # return the display rectangle for the image
        (x0, y0, x1, y1);
    }
    multi method do($img, Numeric $x, Numeric $y = 0, *%opt) {
        self.do($img, :position[$x, $y], |%opt);
    }

    my subset Pattern of Hash where .<PatternType> ~~ 1|2;
    my subset TilingPattern of Pattern where .<PatternType> ~~ 1;
    #| ensure pattern is declared as a resource
    method use-pattern(Pattern $pat!) {
        $pat.finish
            if $pat ~~ TilingPattern;
        :Pattern(self.resource-key($pat));
    }

    #| fill and stroke the current path
    multi method paint(
        Bool :$fill,  Bool :$even-odd,
        Bool :$close, Bool :$stroke,
    ) {
        my @paint-ops = do {
            if $fill {
                if $even-odd {
                    if $close { $stroke ?? <CloseEOFillStroke> !! <ClosePath EOFill> }
                    else      { $stroke ?? <EOFillStroke>      !! <EOFill>       }
                }
                else {
                    if $close { $stroke ?? <CloseFillStroke>   !! <ClosePath Fill>   }
                    else      { $stroke ?? <FillStroke>        !! <Fill>         }
                }
            }
            else {
                if $stroke    { $close ?? <CloseStroke> !! <Stroke> }
                else          { <EndPath> }
            }
        }

        self."$_"()
            for @paint-ops;
    }

    #| build a path, then fill and stroke it
    multi method paint(&meth, *%o) {
        self.Save;
        self.&meth();
        my \rv = self.paint: |%o;
        self.Restore;
        rv;
    }

    my subset MadeFont where {.does(PDF::Content::FontObj) || .?font-obj.defined}
    multi sub make-font(PDF::Content::FontObj:D $_) { $_ }
    #| associate a font dictionary with a font object
    multi sub make-font(
        PDF::COS::Dict:D() $dict where .<Type> ~~ 'Font'
        --> PDF::COS::Dict
    ) {
        $dict.^mixin: PDF::Content::Font
            unless $dict.does(PDF::Content::Font);
        unless $dict.font-obj.defined {
            my $font-loader = try PDF::COS.required("PDF::Font::Loader");
            die "Content font loading is only supported if PDF::Font::Loader is installed"
                if $font-loader === Any;

            my Bool $core-font = $dict<Subtype> ~~ 'Type1'
                             && ! $dict<FontDescriptor>.defined
                             &&  PDF::Content::Font::CoreFont.core-font-name($dict<BaseFont>).defined;
            $dict.make-font: $font-loader.load-font(:$dict, :$core-font);
        }
        $dict;
    }

    #| create a text box object for use in graphics .print() or .say() methods
    method text-box(
        ::?CLASS:D $gfx:
        MadeFont:D :$font = make-font(self!current-font[0]),
        Numeric:D  :$font-size = $.font-size // self!current-font[1],
        *%opt,
        --> PDF::Content::Text::Box
    ) is hidden-from-backtrace {
        PDF::Content::Text::Box.new(
            :$gfx, :$font, :$font-size, |%opt,
        );
    }

    #| output text leave the text position at the end of the current line
    multi method print(
        Str $text,
        *%opt,  # :$align, :$valign, :$kern, :$leading, :$width, :$height, :$baseline-shift, :$font, :$font-size
        --> List
    ) {
        my $text-box = self.text-box( :$text, |%opt);
        @.print( $text-box, |%opt);
    }

    # deprecated in favour of text-box()
    method text-block(::?CLASS:D $gfx: $font = self!current-font[0], *%opt) is DEPRECATED('text-box') {
        my Numeric $font-size = $.font-size // self!current-font[1];
        PDF::Content::Text::Block.new(
            :$gfx, :$font, :$font-size, |%opt,
        );
    }

    method !set-position(
        $text-block, $position,
        Bool :$left! is rw,
        Bool :$top! is rw) {
        my Numeric $x;
        with $position[0] {
            when Numeric {$x = $_}
            when XPos-Pair {
                my constant Dx = %( :left(0.0), :justify(0.0), :center(0.5), :right(1.0) );
                $x = .value  +  Dx{.key} * $text-block.width;
                $left = True; # position from left
            }
        }
        my Numeric $y;
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

    #| get or set the current text position
    method text-position is rw returns Vector {
        warn '$.text-position accessor used outside of a text-block'
            unless $.context == GraphicsContext::Text;

        Proxy.new(
            FETCH => {
                my @tm = @.TextMatrix;
                (@tm[4] + self.tf-x) / @tm[0], @tm[5] / @tm[3];
            },
            STORE => -> $, Vector \v {
                my @tm = @.TextMatrix;
                @tm[4] = $_ * @tm[0] with v[0];
                @tm[5] = $_ * @tm[3] with v[1];
                self.op(SetTextMatrix, @tm);
            },
        );
    }

    #| print a text block object
    multi method print(PDF::Content::Text::Box $text-box,
                       Position :$position,
                       Bool :$nl = False,
                       Bool :$preserve = True,
                       --> List
        ) {

        my Bool $left = False;
        my Bool $top = False;
        my Bool \in-text = $.context == GraphicsContext::Text;

        self.BeginText unless in-text;

        self!set-position($text-box, $_, :$left, :$top)
            with $position;
        my ($x, $y) = $.text-position;
        my ($dx, $dy) = $text-box.render(self, :$nl, :$top, :$left, :$preserve);

        self.EndText() unless in-text;

        unless $.artifact {
            with $!actual-text {
                # Pass agregated text back to callee e.g. PDF::Tags::Elem.mark()
                my $chunk = $text-box.text;
                $chunk .= flip if $.reversed-chars;
                $_ ~= ' '
                    if .so
                    && !(.ends-with(' '|"\n") || $chunk.starts-with(' '|"\n"));
                $_ ~= $chunk;
                $_ ~= "\n" if $nl;
            }
        }

        my \x0 = $x + $dx;
        my \y0 = $y + $dy + $text-box.TextRise;
        my \x1 = x0 + $text-box.width;
        my \y1 = y0 + $text-box.height;

        (x0, y0, x1, y1);
    }

    #| output text; move the text position down one line
    method say($text = '', *%opt) {
        @.print($text, :nl, |%opt);
    }

    #| thin wrapper to $.op(SetFont, ...)
    multi method set-font( Hash $font!, Numeric $size = 16) {
        $.op(SetFont, $.resource-key($font), $size)
            if $.font-face !=== $font || $.font-size != $size;
    }
    multi method set-font( PDF::Content::FontObj $font-obj!, Numeric $size = 16) {
        $.set-font($font-obj.to-dict, $size);
    }

    method !current-font {
        $.Font // [$.core-font('Courier'), 16]
    }

    #| Get or set the current font as ($font, $font-size)
    method font is rw returns Array {
        Proxy.new(
            FETCH => {
                $.Font;
            },
            STORE => -> $, $v {
                my @v = $v.isa(List) ?? @$v !! $v;
                @v[0] = .use-font: @v[0] with $.canvas;
                self.set-font: |@v;
            },
        );
    }

    #| print text to the content stream
    multi method print(Str $text, :$font = self!current-font[0], |c --> List) {
        nextwith( $text, :$font, |c);
    }

    #| add graphics using HTML Canvas 2D API
    method html-canvas(&mark-up!, |c ) {
        my $html-canvas := PDF::COS.required('HTML::Canvas').new;
        $html-canvas.context(&mark-up);
        self.draw($html-canvas, |c);
    }
    =para The HTML::Canvas::To::PDF Raku module must be installed to use this method

    #| render an HTML canvas
    method draw(PDF::Content:D $gfx: $html-canvas, :$renderer, |c) {
        $html-canvas.render($renderer // PDF::COS.required('HTML::Canvas::To::PDF').new: :$gfx, |c);
    }

    #| map transformed user coordinates to untransformed (default) coordinates
    use PDF::Content::Matrix :&dot, :&inverse-dot;
    method base-coords(*@coords where .elems %% 2, :$user = True, :$text = !$user --> Array) {
        (
            my @ = @coords.map: -> $x is copy, $y is copy {
                ($x, $y) = $.TextMatrix.&dot($x, $y) if $text;
                slip($user ?? $.CTM.&dot($x, $y) !! ($x, $y));
            }
        )
    }
    #| inverse of base-coords
    method user-coords(*@coords where .elems %% 2, :$user = True, :$text = !$user --> Array) {
        (
            my @ = @coords.map: -> $x is copy, $y is copy {
                ($x, $y) = $.CTM.&inverse-dot($x, $y) if $user;
                slip($text ?? $.TextMatrix.&inverse-dot($x, $y) !! ($x, $y));
            }
        )
    }
    method user-default-coords(|c) is DEPRECATED('base-coords') {
        $.base-coords(|c);
    }
}
