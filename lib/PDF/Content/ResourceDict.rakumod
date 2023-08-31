#| Applied to a resources dictionary. E.g. in a page or XObject form
unit role PDF::Content::ResourceDict;

use PDF::COS;
use PDF::COS::Name;
use PDF::Content::Font;
use PDF::Content::FontObj;

has Str %!resource-key{PDF::COS}; # resource cache
has Int %!counter;

#| key for the resource, .e.g. /F1 or /Im2
method resource-key(PDF::COS:D $object is raw, |c --> Str:D) {
    self!require-resource($object, |c)
        unless %!resource-key{$object}:exists;
    %!resource-key{$object};
}

method !resource-type(PDF::COS:D $_ ) {
    when Hash {
        when .<Type> ~~ 'ExtGState'|'Font'|'XObject'|'Pattern' {
            .<Type>
        }
        when .<Subtype> ~~ 'Form'|'Image'|'PS' {
            # XObject with /Type defaulted
            'XObject'
        }
        when .<PatternType>:exists { 'Pattern' }
        when .<ShadingType>:exists { 'Shading' }
        default { 'Other' }
    }
    when List && .[0] ~~ PDF::COS::Name {
        # e.g. [ /CalRGB << /WhitePoint [ 1.0 1.0 1.0 ] >> ]
        'ColorSpace'
    }
    default {
        warn "unrecognised graphics resource object: {.raku}";
        'Other'
    }
}

#| Find an existing entry for an object
method find-resource($obj is raw, Str :$type! ) {
    my $key = %!resource-key{$obj};
    $key //= do with self{$type} -> $resources {
        with $resources.keys.first({ $obj === $resources{$_}}) {
            %!resource-key{$obj} = $_;
        }
    }
    $key ?? $obj !! Mu;
}

#| ensure that the object is registered as a page resource. Return a unique
#| name for it.
method !require-resource(
    PDF::COS:D $object is raw,
    Str :$type = self!resource-type($object),
) {
    without $.find-resource($object, :$type) {
        my constant %ResourcePrefix = %(
            :ColorSpace<CS>, :Font<F>, :ExtGState<GS>,
            :Pattern<Pt>, :Shading<Sh>, :Other<Obj>,
        );
        my constant %XObjectPrefix = %( :Form<Fm>, :Image<Im>, :PS<PS> );

        my $prefix = $type eq 'XObject'
            ?? %XObjectPrefix{ $object<Subtype> }
            !! %ResourcePrefix{ $type };

        my Str $key;
        # make a unique resource key
        repeat {
            $key = $prefix ~ ++%!counter{$prefix};
        } while self.keys.first: { self{$_}{$key}:exists };

        self{$type}{$key} = $object;
        %!resource-key{$object} = $key;
    }
    $object;
}

multi method resource(PDF::COS:D $object is raw where { %!resource-key{$_}:exists }) {
    $object;
}

multi method resource(PDF::COS:D $object is raw, Str :$type = self!resource-type($object)) {
    self!require-resource($object, :$type);
}

method resource-entry(Str:D $type!, Str:D $key!) {
    .{$key} with self{$type};
}

method core-font(|c) {
    my $font := PDF::COS.required('PDF::Content::Font::CoreFont').load-font( |c );
    self.resource: $font.to-dict, :type<Font>;
    $font;
}

multi method use-font(PDF::Content::Font:D $font is raw) {
    self.resource: $font, :type<Font>;
}

multi method use-font(PDF::Content::FontObj:D $font-obj is raw) {
    self.resource: $font-obj.to-dict, :type<Font>;
}
