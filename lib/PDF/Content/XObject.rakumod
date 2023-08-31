#| base role for XObjects
role PDF::Content::XObject {
    use PDF::Content::Image :&make-data-uri;
    use PDF::COS::Stream;

    my subset XObjectType of Str where 'Form'|'Image'|'PS';

    #| load from in-memory data
    multi method open(
        PDF::Content::Image::IOish :$source!,
        Str :$image-type!,
       ) {
        self.open: make-data-uri( :$source, :$image-type);
    }

    #| load from a file or data-uri
    multi method open(\fh = self, |c) {
        my PDF::Content::Image $image-obj .= load(fh, |c);
        $image-obj.read;
        my PDF::COS::Stream $xobject = $image-obj.to-dict;
        my XObjectType $sub-type = $xobject<Subtype>;
        $xobject does PDF::Content::XObject[$sub-type]
            unless $xobject ~~ PDF::Content::XObject;
        $xobject.image-obj = $image-obj;
        $xobject;
    }

}

#| XObject form specific role
role PDF::Content::XObject['Form']
    does PDF::Content::XObject {
    has Numeric $.width;
    has Numeric $.height;

    my proto sub from-origin($) is export(:from-origin) {*} 

    multi sub from-origin(List:D $_) {
        enum <x0 y0 x1 y1>;
        when .[x1] < .[x0] {
            from-origin([ .[x1], .[y0], .[x0], .[y1] ]);
        }
        when .[y1] < .[y0] {
            from-origin([ .[x0], .[y1], .[x1], .[y0] ]);
        }
        default { $_ }
    }

    multi sub from-origin(Any:U) { Any }

    method width  { with $!width  { $_ } else { self!size()[0] } }
    method height { with $!height { $_ } else { self!size()[1] } }
    method bbox { from-origin(self<BBox>) }
    method !size {
        my $bbox = self.bbox();
        $!width  = $bbox[2] - $bbox[0];
        $!height = $bbox[3] - $bbox[1];
        ($!width, $!height);
    }
}

#| XObject image specific role
role PDF::Content::XObject['Image']
    does PDF::Content::XObject {
    has Numeric $.width;
    has Numeric $.height;
    method width  { $!width //= self<Width> }
    method height { $!height //= self<Height> }
    method bbox   {[0, 0, $.width, $.height]}
    has $.image-obj is rw handles <data-uri source image-type>;
    method Str { with $!image-obj  {.data-uri} else {nextsame} }

    method inline-to-xobject(Hash $inline-dict, Bool :$invert) {

        my constant %Abbreviations = %(
            # [PDF 1.7 TABLE 4.43 Entries in an inline image object]
            :BPC<BitsPerComponent>,
            :CS<ColorSpace>,
            :D<Decode>,
            :DP<DecodeParms>,
            :F<Filter>,
            :H<Height>,
            :IM<ImageMask>,
            :I<Interpolate>,
            :W<Width>,
            # [PDF 1.7 TABLE 4.44 Additional abbreviations in an inline image object]
            :G<DeviceGray>,
            :RGB<DeviceRGB>,
            :CMYK<DeviceCMYK>,
            # Notes:
            # 1. ambiguous 'Indexed' entry seems to be a typo in the spec
            # 2. filter abbreviations are handled in PDF::IO::Filter
            );
        my constant %Expansions = %( %Abbreviations.invert );

        my $alias = $invert ?? %Expansions !! %Abbreviations;

        my %xobject-dict = $inline-dict.pairs.map: {
            ($alias{.key} // .key) => .value
        }
        if $invert {
            %xobject-dict<Type Subtype Length>:delete;
        }
        else {
            %xobject-dict<Type> = :name<XObject>;
            %xobject-dict<Subtype> = :name<Image>;
        }

        %xobject-dict;
    }

    method inline-content {

        # for serialization to content stream ops: BI dict ID data EI
        use PDF::Content::Ops :OpCode;
        use PDF::COS::Util :ast-coerce;
        # serialize to content ops
        my %dict = ast-coerce(self).value.list;
        %dict = self.inline-to-xobject( %dict, :invert );

        [ (BeginImage) => [ :%dict ],
          (ImageData)  => [ :$.encoded ],
          (EndImage)   => [],
        ]
    }
}

role PDF::Content::XObject['PS'] {
    # stub
}
