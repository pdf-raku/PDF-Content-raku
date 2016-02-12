use v6;

role PDF::Graphics::ResourceDict {

    use PDF::DAO;

    my role ResourceEntry {
	has Str $.key is rw;
    }

    method !base-name( PDF::DAO $object ) is default {
        my Str $type = $object.?type
            // die "not a resource object: {$object.WHAT}";

        do given $type {
	    when 'ColorSpace' {'CS'}
            when 'ExtGState'  {'GS'}
            when 'Font'       {'F'}
            when 'Pattern'    {'Pt'}
	    when 'Shading'    {'Sh'}
            when 'XObject' {
                given $object.Subtype {
                    when 'Form'  {'Fm'}
                    when 'Image' {'Im'}
		    default { warn "unknown XObject subtype: $_"; 'Obj' }
		}
            }
            default { warn "unknown object type: $_"; 'Obj' }
        }
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
                             Str :$base-name = self!base-name($object),
                             :$type = $object.?type) {

	die "unable to register this resource - uknown type"
	    unless $type.defined;

        my Str $key = (1..*).map({$base-name ~ $_}).first({ self{$type}{$_}:!exists });
        self{$type}{$key} = $object;

        my $entry = $object but ResourceEntry;
        $entry.key = $key;
        $entry;
    }

    method resource(PDF::DAO $object, Bool :$eqv=False ) {
        my Str $type = $object.?type
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
