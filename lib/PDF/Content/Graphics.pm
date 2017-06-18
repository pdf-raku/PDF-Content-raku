use v6;

#| this role is applied to PDF::Content::Type::Page, PDF::Content::Type::Pattern and PDF::Content::Type::XObject::Form
role PDF::Content::Graphics {

    use PDF::Content;
    use PDF::Content::Ops :OpCode;

    has PDF::Content $!pre-gfx; #| prepended graphics
    method pre-gfx { $!pre-gfx //= PDF::Content.new( :parent(self) ) }
    method pre-graphics(&code) { self.pre-gfx.graphics( &code ) }
    has PDF::Content $!gfx;     #| appended graphics

    method !tidy-ops(@ops) {
        my int $nesting = 0;
        my $wrap = False;

        for @ops {
            given .key {
                when OpCode::Save {$nesting++}
                when OpCode::Restore {$nesting--}
                default {
                    $wrap = True
                        if $nesting <= 0
                        && PDF::Content::Ops.is-graphics-op: $_;
                }
            }
        }

        @ops.push: OpCode::Restore => []
            while $nesting-- > 0;

	if $wrap {
	    @ops.unshift: OpCode::Save => [];
	    @ops.push: OpCode::Restore => [];
	}
        @ops;
    }

    method gfx(Bool :$raw, |c) {
	$!gfx //= do {
	    my Pair @ops = self.contents-parse;
            @ops = self!tidy-ops(@ops)
                unless $raw;
	    my PDF::Content $gfx .= new( :parent(self), |c );
	    $gfx.ops: @ops;
	    $gfx;
	}
    }
    method graphics(&code) { self.gfx.graphics( &code ) }
    method text(&code) { self.gfx.text( &code ) }
    method canvas(&code) { self.gfx.canvas( &code ) }

    method contents-parse(Str $contents = $.contents ) {
        PDF::Content.parse($contents);
    }

    method contents returns Str {
	$.decoded // '';
    }

    method add-callback(&callback) {
        with $!gfx {
            die "too late to install render callback"
                if .ops;
        }
	$.gfx.callback.push: &callback;
    }

    method new-gfx {
        $.gfx.new( :parent(self) );
    }

    method finish {
        my $decoded = do with $!pre-gfx { .content } else { '' };
        $decoded ~= "\n" if $decoded;
        $decoded ~= do with $!gfx { .content } else { '' };

        self.decoded = $decoded;
    }

    method cb-finish { $.finish }
}
