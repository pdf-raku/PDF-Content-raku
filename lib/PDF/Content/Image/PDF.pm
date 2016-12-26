use v6;
# doesn't work if this 'use' statement is deleted
# rakudo 2016.11 read invocation: No such symbol 'PDF::Lite'
use PDF::Content::Image;

class PDF::Content::Image::PDF {
    method read($fh) {
        my $class = (require ::('PDF::Lite'));
        $fh.seek(0, SeekFromBeginning);
        my $header = $fh.read(4).decode: 'latin-1';
        die X::PDF::Image::WrongHeader.new( :type<PDF>, :$header, :path($fh.path) )
            unless $header ~~ "%PDF";
        my $pdf = $class.open($fh);
        my $page1 = $pdf.page(1) // die "PDF contains no pages";
        $page1.to-xobject;
    }
}
