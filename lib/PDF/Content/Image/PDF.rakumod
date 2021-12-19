use v6;

use PDF::Content::Image;

class PDF::Content::Image::PDF
  is PDF::Content::Image {

    has $!page;
    has $!dict;

    method read($fh = $.source, UInt :$page-num = 1) {
        $fh.seek(0, SeekFromBeginning);
        my $header = $fh.read(4).decode: 'latin-1';
        die X::PDF::Image::WrongHeader.new( :type<PDF>, :$header, :path($fh.path) )
            unless $header ~~ "%PDF";
        my $pdf = self.loader.pdf-class.open($fh);
        $!page = $pdf.page($page-num) // die "PDF contains no page number: $page-num";
    }
    method to-dict {
        $!dict //= $!page.to-xobject;
    }

}

