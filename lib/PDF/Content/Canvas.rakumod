
#| A graphical content container such as a page, xobject form, or pattern
unit role PDF::Content::Canvas;
=para this role is applied to L<PDF::Content::Page> and L<PDF::Content::XObject>C<['Form']>.

use PDF::Content::Resourced;
also does PDF::Content::Resourced;

use PDF::COS;
use PDF::Content;
use PDF::Content::Ops :OpCode;
use PDF::Content::Tag;
use PDF::COS::Stream;
use PDF::COS::Name;
use PDF::Content::XObject;
sub name($_) { PDF::COS::Name.COERCE: $_ }

has PDF::Content $!gfx;     #| appended graphics
#| return appended PDF content stream
method gfx(::?ROLE:D $canvas: |c --> PDF::Content) handles<html-canvas graphics text> {
    $!gfx //= PDF::Content.new: :$canvas, |c
}

has PDF::Content $!pre-gfx;
method has-pre-gfx returns Bool { ? (.ops with $!pre-gfx) }
#| return prepended graphics
method pre-gfx returns PDF::Content { $!pre-gfx //= PDF::Content.new( :canvas(self) ) }
method pre-graphics(&code) { self.pre-gfx.graphics( &code ) }
has Bool $!rendered = False;
has UInt $.mcid = 0;
method use-mcid(UInt:D $_) {
    $!mcid = $_ unless $!mcid >= $_;
}
#| Allocate the next MCID (Marked Content Identifier)
method next-mcid returns UInt:D { $!mcid++ }

method canvas(&code) is DEPRECATED<html-canvas> { self.html-canvas(&code) }

# Fix nesting issues that aren't illegal, but could cause problems:
# - append any missing 'Q' (Restore) operators at end of stream
# - wrap with 'q' (Save) and 'Q' (Restore) operators, if there
#   are any top-level graphics, which may affect the state.
method !tidy(@ops --> Array) {
    my int $nesting = 0;
    my $wrap = False;

    for @ops {
        given .key {
            when OpCode::Save {$nesting++}
            when OpCode::Restore {$nesting--}
            default {
                $wrap ||= $nesting <= 0
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

#| return contents
method contents returns Str {
    with $.decoded {
       .isa(Str) ?? $_ !! .Str;
    }
    else {
        ''
    }
}

#| reparse contents
method contents-parse {
    PDF::Content.parse($.contents);
}

method new-gfx(::?ROLE:D $canvas: |c) is DEPRECATED {
    PDF::Content.new: :$canvas, |c;
}

#| render graphics
method render(Bool :$tidy = True, |c --> PDF::Content) {
    my $gfx := $.gfx(|c);
    $!rendered ||= do {
        my Pair @ops = self.contents-parse;
        @ops = self!tidy(@ops)
            if $tidy;
        $gfx.ops: @ops;
        True;
    }
    $gfx;
}

#| finish for serialization purposes
method finish is hidden-from-backtrace {
    if $!gfx.defined || $!pre-gfx.defined {
        # rebuild graphics, if they've been accessed
        my $decoded = do with $!pre-gfx { .Str } else { '' };
        if !$!rendered && $.contents {
            # skipping rendering. copy raw content
            $decoded ~= "\n" if $decoded;
            $decoded ~= ~ OpCode::Save ~ "\n"
                ~ $.contents
                ~ "\n" ~ OpCode::Restore;
        }
        with $!gfx {
            $decoded ~= "\n" if $decoded;
            $decoded ~= .Str;
        }
        $!gfx = $!pre-gfx = Nil;
        self.decoded = $decoded;
    }
}

method cb-finish is hidden-from-backtrace { $.finish }

#| create a child XObject Form
method xobject-form(:$group = True, *%dict --> PDF::Content::XObject) {
    %dict<Type> = name 'XObject';
    %dict<Subtype> = name 'Form';
    %dict<Resources> //= {};
    %dict<BBox> //= [0, 0, 612, 792];
    %dict<Group> //= %( :S( name 'Transparency' ) )
        if $group;
    PDF::COS::Stream.COERCE: { :%dict };
}

#| create a new Type 1 (Tiling) Pattern
method tiling-pattern(List    :$BBox!,
                      Numeric :$XStep = $BBox[2] - $BBox[0],
                      Numeric :$YStep = $BBox[3] - $BBox[1],
                      Int :$PaintType = 1,
                      Int :$TilingType = 1,
                      Hash :$Resources = {},
                      *%dict
                      --> PDF::Content::XObject
                     ) {
    %dict.push: $_
                 for (:Type(name 'Pattern'), :PatternType(1),
                      :$PaintType, :$TilingType,
                      :$BBox, :$XStep, :$YStep, :$Resources);
    PDF::COS::Stream.COERCE: { :%dict };
}
my subset ImageFile of Str where /:i '.'('png'|'svg'|'pdf') $/;

#| draft rendering via Cairo (experimental)
method save-as-image(ImageFile $outfile, |c) {
    (try require PDF::To::Cairo) !=== Nil
         or die "save-as-image method is only supported if PDF::To::Cairo is installed";
    ::('PDF::To::Cairo').save-as-image(self, $outfile, |c);
}
=para The L<PDF::To::Cairo> module must be installed to use this method

# *** Marked Content Tags ***
my class TagSetBuilder is PDF::Content::Tag::NodeSet {
    has PDF::Content::Tag @.open-tags;            # currently open descendant tags
    has PDF::Content::Tag $.closed-tag;
    has UInt $.artifact is built;
    has UInt $.reversed-chars is built;

    method open-tag(PDF::Content::Tag $tag) {     # open a new descendant
        $!artifact++ if $tag.name eq 'Artifact';
        $!reversed-chars++ if $tag.name eq 'ReversedChars';
        with @!open-tags.tail {
            .add-kid: $tag;
        }
        @!open-tags.push: $tag;
    }

    method close-tag returns PDF::Content::Tag {                            # close innermost descendant
        $!closed-tag = @!open-tags.pop;
        $!artifact-- if $!closed-tag.name eq 'Artifact';
        $!reversed-chars-- if $!closed-tag.name eq 'ReversedChars';
        @.tags.push: $!closed-tag
            without $!closed-tag.parent;
        $!closed-tag;
    }

    method add-tag(PDF::Content::Tag $tag) {      # add child to innermost descendant
        with @!open-tags.tail {
            .add-kid: $tag;
        }
        else {
            @.tags.push: $tag;
        }
    }
}
#| snapshot of previous, and currently open tags
has TagSetBuilder $.tags .= new();
