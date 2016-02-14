use v6;

role PDF::Graphics::ResourceDict {

    use PDF::DAO;
    use PDF::DAO::Name;

    my role ResourceEntry {
	has Str $.key is rw;
    }

    method !type( PDF::DAO $object ) is default {

        my $type = do given $object {
	    when Hash {
		when .<Type>:exists {
		    given .<Type> {
			when 'ExtGState' | 'Font' | 'XObject' | 'Pattern' { $_ }
		    }
		}
		when .<PatternType>:exists { 'Pattern' }
		when .<ShadingType>:exists { 'Shading' }
		when .<Subtype>:exists && .<Subtype> ~~ 'Form' | 'Image' | 'PS' {
		    # XObject /Type with /Type defaulted
		    'XObject'
		}
	    }
	    when Array && .[0] ~~ PDF::DAO::Name {
		# e.g. [ /CalRGB << /WhitePoint [ 1.0 1.0 1.0 ] >> ]
		'ColorSpace'
	    }
        };
	
	unless $type {
	    warn "unrecognised graphics object: {$object.perl}";
	    $type = 'Other'
	}
	
	$type;
    }

    method !find-resource( &match, Str :$type! ) {
        my $entry;

        if my $resources = self{$type} {

            for $resources.keys {
                my $resource = $resources{$_};
                if &match($resource) {
                    $entry = $resource but ResourceEntry;
                    $entry.key = $_;
                    last;
                }
            }
        }

        $entry;
    }

    #| ensure that the object is registered as a page resource. Return a unique
    #| name for it.
    method !register-resource(PDF::DAO $object,
                             Str :$type = self!type($object),
	) {

	my constant %Prefix = %(
	    :ColorSpace<CS>, :Font<F>, :ExtGState<GS>, :Pattern<Pt>, :Shading<Sh>,
	    :XObject{  :Form<Fm>, :Image<Im>, :PS<PS> },
	    :Other<Obj>,
	);

	my $prefix = $type eq 'XObject'
	    ?? %Prefix{$type}{ $object<Subtype> }
	    !! %Prefix{$type};

        my Str $key = (1..*).map({$prefix ~ $_}).first({ self{$type}{$_}:!exists });
        self{$type}{$key} = $object;

        my $entry = $object but ResourceEntry;
        $entry.key = $key;
        $entry;
    }

    method resource(PDF::DAO $object, Bool :$eqv=False ) {
        my Str $type = self!type($object)
            // die "not a resource object: {$object.WHAT}";

	my &match = $eqv
	    ?? sub ($_){$_ eqv $object}
	    !! sub ($_){$_ === $object};
        self!find-resource(&match, :$type)
            // self!register-resource( $object );
    }

    method resource-entry(Str $type!, Str $key!) {
        return unless
            (self{$type}:exists)
            && (self{$type}{$key}:exists);

        my $object = self{$type}{$key};

        my $entry = $object but ResourceEntry;
        $entry.key = $key;
        $entry;
    }

}
