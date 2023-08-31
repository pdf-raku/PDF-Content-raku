#| Treat a PDF as an image
unit class PDF::Content::Image::PDF;

use PDF::Content::Image;
also is PDF::Content::Image;

=head2 Description

=para This class logically treats a PDF as an image.

has $!page;
has $!dict;

#| Load a particular page as the image
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


