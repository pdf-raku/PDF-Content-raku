use v6;

#| this role is applied to PDF::Content::Type::Page, PDF::Content::Type::Pattern and PDF::Content::Type::XObject::Form
role PDF::Content::Graphics {

    use PDF::Content;
    use PDF::Content::Ops :OpCode;

    has PDF::Content $!pre-gfx; #| prepended graphics
    method pre-gfx { $!pre-gfx //= PDF::Content.new( :parent(self) ) }
    method pre-graphics(&code) { self.pre-gfx.graphics( &code ) }

    has PDF::Content $!gfx;     #| appended graphics
    method gfx(|c) {
	$!gfx //= do {
	    my Pair @ops = self.contents-parse;
	    my PDF::Content $gfx .= new( :parent(self), |c );
	    if @ops && ! (@ops[0].key eq OpCode::Save && @ops[*-1].key eq OpCode::Restore) {
		@ops.unshift: OpCode::Save => [];
		@ops.push: OpCode::Restore => [];
	    }
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

    method render(&callback) {
	die "too late to install render callback"
	    if $!gfx;
	self.gfx(:&callback);
    }

    method finish {
        my $decoded = do with $!pre-gfx { .content } else { '' };
        $decoded ~= "\n" if $decoded;
        $decoded ~= do with $!gfx { .content } else { '' };

        self.decoded = $decoded;
    }

    method cb-finish { $.finish }
}
