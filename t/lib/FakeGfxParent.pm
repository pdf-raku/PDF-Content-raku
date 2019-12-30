role FakeGfxParent {
    has $!key = 'R0';
    has Str %!keys{Any};
    has UInt $.mcid;
    method find-resource(&match, :$type) {
        my $entry;

        with self{$type} -> $resources {

            for $resources.keys {
                my $resource = $resources{$_};
                if &match($resource) {
		    $entry = $resource;
                    last;
                }
            }
        }

        $entry;
     }
    method use-resource($obj) {
        %!keys{$obj} = ++ $!key;
        self{$obj<Type>}{$!key} = $obj;
        $obj;
    }
    method resource-key($obj) {
        $.use-resource($obj)
            unless %!keys{$obj}:exists;
        %!keys{$obj};
    }
    method resource-entry($a,$b) {
        self{$a}{$b};
    }
    method resources($a) {
        self{$a}
    }
    method use-mcid(UInt:D $_) {
        $!mcid = $_ unless ($!mcid//-1) >= $_;
    }
    method next-mcid { ++$!mcid }
}
