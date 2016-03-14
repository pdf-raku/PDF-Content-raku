use v6;

use PDF::Basic;

#| this role is applied to PDF::Basic::Type::Page, PDF::Basic::Type::Pattern and PDF::Basic::Type::XObject::Form
role PDF::Basic::Graphics {

    use PDF::Basic;
    use PDF::Basic::Ops :OpNames;

    has PDF::Basic $!pre-gfx; #| prepended graphics
    method pre-gfx { $!pre-gfx //= PDF::Basic.new( :parent(self) ) }
    method pre-graphics(&code) { self.pre-gfx.block( &code ) }

    has PDF::Basic $!gfx;     #| appended graphics
    method gfx(|c) {
	$!gfx //= do {
	    my Pair @ops = self.contents-parse;
	    my PDF::Basic $gfx .= new( :parent(self), |c );
	    if @ops && ! (@ops[0].key eq OpNames::Save && @ops[*-1].key eq OpNames::Restore) {
		@ops.unshift: OpNames::Save => [];
		@ops.push: OpNames::Restore => [];
	    }
	    $gfx.ops: @ops;
	    $gfx;
	}
    }
    method graphics(&code) { self.gfx.block( &code ) }
    method text(&code) { self.gfx.text( &code ) }

    method contents-parse(Str $contents = $.contents ) {
        PDF::Basic.parse($contents);
    }

    method contents returns Str {
	$.decoded // '';
    }

    method render(&callback) {
	die "too late to install render callback"
	    if $!gfx;
	self.gfx(:&callback);
    }

    method cb-finish {

        my $prepend = $!pre-gfx && $!pre-gfx.ops
            ?? $!pre-gfx.content ~ "\n"
            !! '';

        my $append = $!gfx && $!gfx.ops
            ?? $!gfx.content
            !! '';

        self.decoded = $prepend ~ $append;
    }

}
