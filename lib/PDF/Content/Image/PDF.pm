use v6;
use PDF::Content::Image;
class PDF::Content::Image::PDF {
    method read($fh) {
        # not working: No such symbol 'PDF::Content::PDF'
        my $class = (require ::('PDF::Content::PDF'));
        $fh.seek(0, SeekFromBeginning);
        my $header = $fh.read(4).decode: 'latin-1';
        die X::PDF::Image::WrongHeader.new( :type<PDF>, :$header, :path($fh.path) )
            unless $header ~~ "%PDF";
        my $pdf = $class.open($fh);
        my $page1 = $pdf.page(1) // die "PDF contains no pages";
        $page1.to-xobject;
    }
}
