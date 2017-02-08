role PDF::Content::XObject['Form'] {
    has Numeric $.width;
    has Numeric $.height;
    method width  { with $!width  { $_ } else { self!size()[0] } }
    method height { with $!height { $_ } else { self!size()[1] } }
    method !size {
        my $bbox = self<BBox>;
        $!width  = $bbox[2] - $bbox[0];
        $!height = $bbox[3] - $bbox[1];
        ($!width, $!height);
    }
}

role PDF::Content::XObject['Image'] {
    has Numeric $.width;
    has Numeric $.height;
    method width  { with $!width  { $_ } else { self!size()[0] } }
    method height { with $!height { $_ } else { self!size()[1] } }
    method !size {
        $!width  = self<Width>;
        $!height = self<Height>;
        ($!width, $!height);
    }
    has Str $.data-uri;
    my subset Str-or-IOHandle where Str|IO::Handle;
    has Str-or-IOHandle $.source;
    has Str $.image-type;
    method set-source(Str-or-IOHandle :$!source, :$!image-type, :$data-uri) {}

    method data-uri is rw {
        Proxy.new(
            FETCH => sub ($) {
                $!data-uri //= do {
                    with $!source {
                        use Base64;
                        my Str $bytes = .isa(Str)
                            ?? .substr(0)
                            !! .path.IO.slurp(:enc<latin-1>);
                        my $enc = encode-base64($bytes, :str);
                        'data:image/%s;base64,%s'.sprintf($.image-type.lc, $enc);
                    }
                    else {
                        fail 'image is not associated with a sourxe';
                    }
                }
            },
            STORE => sub ($, $!data-uri) {},
        )
    }

    method Str { self.data-uri }
}

role PDF::Content::XObject['PS'] {
    # stub
}
