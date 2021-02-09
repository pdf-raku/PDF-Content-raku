use Test;
plan 6;

use lib 't';
use PDFTiny;

my PDFTiny $pdf .= new;

given $pdf.add-page.gfx {
    .MoveTo(10,10);
    is-deeply .current-point, (10, 10);

    .Rectangle(40,42,10,10);
    is-deeply .current-point, (40, 42);

    .LineTo(20, 20);
    is-deeply .current-point, (20, 20);

    .LineTo(15, 25);
    is-deeply .current-point, (15, 25);

    .ClosePath;
    is-deeply .current-point, (40, 42);

    .Stroke;
    is-deeply .current-point, (Numeric, Numeric);
}

done-testing;
