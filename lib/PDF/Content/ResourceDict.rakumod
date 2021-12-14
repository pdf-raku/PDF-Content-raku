use v6;

role PDF::Content::ResourceDict {

    use PDF::COS;
    use PDF::COS::Name;
    use PDF::Content::Font;
    use PDF::Content::FontObj;

    has Str %!resource-key{PDF::COS};
    has Int %!counter;

    method resource-key(PDF::COS $object is raw, |c --> Str:D) {
        self!require-resource($object, |c)
            unless %!resource-key{$object}:exists;
       %!resource-key{$object};
    }

    method !resource-type( PDF::COS $_ ) {
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

    method find-resource($entry is raw, Str :$type! ) {
        my $found;

        with self{$type} -> $resources {

            for $resources.keys {
                if $entry === $resources{$_} {
                    $found = True;
		    %!resource-key{$entry} //= $_;
                    last;
                }
            }
        }

        $found ?? $entry !! Mu;
    }

    #| ensure that the object is registered as a page resource. Return a unique
    #| name for it.
    method !require-resource(
        PDF::COS $object is raw,
        Str :$type = self!resource-type($object),
    ) {
        unless $.find-resource($object, :$type) {
            my constant %Prefix = %(
                :ColorSpace<CS>, :Font<F>, :ExtGState<GS>, :Pattern<Pt>,
                :Shading<Sh>, :XObject{  :Form<Fm>, :Image<Im>, :PS<PS> },
                :Other<Obj>,
            );

            my $prefix = $type eq 'XObject'
                ?? %Prefix{$type}{ $object<Subtype> }
                !! %Prefix{$type};

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

    multi method resource(PDF::COS $object is raw where { %!resource-key{$_}:exists }) is default {
	$object;
    }

    multi method resource(PDF::COS $object is raw, :$type = self!resource-type($object)) {
        self!require-resource($object, :$type);
    }

    method resource-entry(Str:D $type!, Str:D $key!) {
        .{$key} with self{$type};
    }

    method core-font(|c) {
        my $font := (require ::('PDF::Content::Font::CoreFont')).load-font( |c );
        self.resource: $font.to-dict, :type<Font>;
        $font;
    }

    multi method use-font(PDF::Content::Font $font is raw) {
        self.resource: $font, :type<Font>;
    }

    multi method use-font(PDF::Content::FontObj $font-obj is raw) {
        self.resource: $font-obj.to-dict, :type<Font>;
    }

}
