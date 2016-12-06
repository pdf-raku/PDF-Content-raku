role PDF::Content::XObject {
    has Numeric $.width;
    has Numeric $.height;
    method width  { with $!width { $_ } else { self!size()[0] } }
    method height { with $!height { $_ } else { self!size()[1] } }
    method !size {
        given self<Subtype> {
            when 'Image' {
                $!width = self<Width>;
                $!height = self<Height>
            }
            when 'Form' {
                my $bbox = self<BBox>;
                $!width = $bbox[2] - $bbox[0];
                $!height = $bbox[3] - $bbox[1];
            }
            default {
                die "not an XObject Image";
            }
        }
        ($!width, $!height);
    }
    has Str $.image-type;
    has Str $.data-uri;
    my subset Str-or-IOHandle where Str|IO::Handle;
    has Str-or-IOHandle $!source;
    method set-source(Str-or-IOHandle :$!source, :$!image-type, :$data-uri) {}
    method data-uri is rw {
        Proxy.new(
            FETCH => sub ($) {
                $!data-uri //= do {
                    use Base64;
                    my $raw = do with $!source {
                        .isa(Str)
                            ?? .substr(0)
                            !! .path.IO.slurp(:bin);
                    }
                    my $enc = encode-base64($raw, :str);
                    sprintf 'data:image/%s;base64,%s', $!image-type.lc, $enc;
                }
            },
            STORE => sub ($, $!data-uri) {},
        )
    }
}
