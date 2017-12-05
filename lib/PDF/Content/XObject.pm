use v6;

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
    has $.image-obj is rw handles <data-uri source image-type>;
    method Str { self.data-uri }
}

role PDF::Content::XObject['PS'] {
    # stub
}
