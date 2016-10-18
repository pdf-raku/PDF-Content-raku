use v6;
use Test;

# ensure consistant document ID generation
srand(123456);

use PDF::Content::PDF;
my PDF::Content::PDF $pdf .= new;
my $page = $pdf.add-page;
my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );

$page.canvas: {
    .beginPath();
    .arc(95, 50, 40, 0, 2 * pi);
    .stroke();
    .fillText("Hello World", 10, 50);
}

lives-ok { $pdf.save-as("t/pdf-canvas.pdf") }, 'save-as';

throws-like { $pdf.unknown-method }, X::Method::NotFound, '$pdf unknown method';

done-testing;
