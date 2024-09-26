class X::PDF::Image::WrongHeader is Exception {
    has Str $.type is required;
    has Str $.header is required;
    has $.path is required;
    method message {
        "$!path image doesn't have a $!type header: {$.header.raku}"
    }
}

class X::PDF::Image::UnknownType is Exception {
    has $.path is required;
    method message {
        "Unable to open as an image: $!path";
    }
}

class X::PDF::Image::UnknownMimeType is Exception {
    has $.path is required;
    has $.mime-type is required;
    method message {
        "Expected mime-type 'image/*' or 'application/pdf', got '$!mime-type': $!path"
    }
}

#| loading and manipulation of PDF images
class PDF::Content::Image {
    use PDF::COS;
    use PDF::COS::Stream;
    use PDF::IO;

=begin pod

=head2 Synopsis

=begin code :lang<raku>
use PDF::Content::Image;
my PDF::Content::Image $image .= open: "t/images/lightbulb.gif";
say "image has size {$image.width} X {$image.height}";
say $image.data-uri;
# data:image/gif;base64,R0lGODlhEwATAMQA...
=end code

=head2 Description

This class currently supports image formats: PNG, GIF and JPEG.

=head2Methods

=end pod

    has Str $.data-uri;
    subset IOish where PDF::IO|IO::Handle;
    has IOish $.source;
    subset ImageType of Str:D where 'JPEG'|'GIF'|'PNG'|'PDF';
    subset DataURI   of Str:D where m/^('data:' [<ident> '/' <ident>]? ";base64"? ",")/;
    has ImageType $.image-type;

    method !image-type($_, :$path! --> ImageType) {
        when m:i/^ jpe?g $/    { 'JPEG' }
        when m:i/^ gif $/      { 'GIF' }
        when m:i/^ png $/      { 'PNG' }
        when m:i/^ pdf|json $/ { 'PDF' }
        default {
            die X::PDF::Image::UnknownType.new( :$path );
        }
    }

    #| load an image from a data URI string
    multi method load(DataURI $data-uri where m/^('data:' [<t=.ident> '/' <s=.ident>]? $<b64>=";base64"? $<start>=",") / --> ::?CLASS:D) {
        my $path = ~ $0;
        my Str $mime-type = ( $0<t> // '(missing)').lc;
        my Str $mime-subtype = ( $0<s> // '').lc;
        my Bool \base64 = ? $0<b64>;
        my Numeric \start = $0<start>.to;

        die X::PDF::Image::UnknownMimeType.new: :$mime-type, :$path
            unless $mime-type eq 'image' || $mime-subtype eq 'pdf';
        my $image-type = self!image-type($mime-subtype, :$path);
        my $data = substr($data-uri, start);
	if base64 {
	    use Base64::Native;
	    $data = base64-decode($data).decode("latin-1");
	}

        my $source = PDF::IO.COERCE($data, :$path);
        self!image-handler(:$image-type).new: :$source, :$data-uri, :$image-type;
    }

    #| load an image from a path
    multi method load(IO::Path() $io-path --> ::?CLASS:D) {
        self.load( $io-path.open( :r, :bin) );
    }

    method !image-handler(Str :$image-type!) {
        PDF::COS.required("PDF::Content::Image::$image-type");
    }

    #| load an image from an IO handle
    multi method load(IO::Handle $source! --> ::?CLASS:D) {
        my $path = $source.path;
        my Str $image-type = self!image-type($path.extension, :$path);
        self!image-handler(:$image-type).new: :$source, :$image-type;
    }

    # build a data uri from a binary source with a given image-type
    sub make-data-uri(Str :$image-type!, :$source! --> Str) is export(:make-data-uri) {
        with $source {
            use Base64::Native;
            my Blob $bytes = .isa(Str)
                ?? .encode("latin-1")
                !! .path.IO.slurp(:bin);
            my $class = $image-type.lc eq 'pdf' ?? 'application' !! 'image';
            my $enc = base64-encode($bytes.decode("latin-1"), :str, :enc<latin-1>);
            'data:%s/%s;base64,%s'.sprintf($class, $image-type.lc, $enc);
        }
        else {
            fail 'image is not associated with a source';
        }
    }

    #| Get or set the data URI from an image
    method data-uri returns DataURI is rw {
        Proxy.new(
            FETCH => {
                $!data-uri //= make-data-uri( :$.image-type, :$!source );
            },
            STORE => -> $, $!data-uri {},
        )
    }

    method open(|c) is DEPRECATED<PDF::Content::XObject.open> {
        PDF::COS.required('PDF::Content::XObject').open(|c);
    }
}
