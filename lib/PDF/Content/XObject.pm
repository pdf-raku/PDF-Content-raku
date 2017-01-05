my role XObject {
    has Str $.data-uri;
    my subset Str-or-IOHandle where Str|IO::Handle;
    has Str-or-IOHandle $.source;
    has Str $.image-type;
    method set-source(Str-or-IOHandle :$!source, :$!image-type, :$data-uri) {}
    method !wrap-form {
        # wrap this form in a single page PDF
        my $pdf = (require ::('PDF::Lite')).new;
        my $page = $pdf.add-page;
        $page<MediaBox> = $_ with self.?bbox;
        $page.do(self);
        $pdf.Str;
    }

    method data-uri is rw {
        Proxy.new(
            FETCH => sub ($) {
                $!data-uri //= do {
                    use Base64;
                    my $type = $.image-type.lc;
                    my Str $bytes = do with $!source {
                        .isa(Str)
                            ?? .substr(0)
                            !! .path.IO.slurp(:enc<latin-1>);
                    }
                    else {
                        $type = 'pdf';
                        self!wrap-form;
                    }
                    my $enc = encode-base64($bytes, :str);
                    sprintf 'data:image/%s;base64,%s', $type, $enc;
                }
            },
            STORE => sub ($, $!data-uri) {},
        )
    }

    method Str { self.data-uri }
}

role PDF::Content::XObject['Form'] does XObject {
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
    method bbox { self<BBox> }
    method image-type { 'PDF' }
}

role PDF::Content::XObject['Image'] does XObject {
    has Numeric $.width;
    has Numeric $.height;
    method width  { with $!width  { $_ } else { self!size()[0] } }
    method height { with $!height { $_ } else { self!size()[1] } }
    method !size {
        $!width  = self<Width>;
        $!height = self<Height>;
        ($!width, $!height);
    }
    method bbox { [0, 0, self<Width>, self<Height> ] }
}

role PDF::Content::XObject['PS'] does XObject {}
