use Test;
use PDF::Grammar::Test :&is-json-equiv;
plan 8;

use lib 't';
use PDFTiny;

my PDFTiny $pdf .= new;

given $pdf.add-page.gfx {
    .current-point = 10, 10; # equivalent to move-to
    is-deeply .current-point, (10, 10);
    is-json-equiv .ops, (:m[:real(10), :real(10)], );

    .current-point = 10, 10; # should be ignored
    is-json-equiv .ops, (:m[:real(10), :real(10)], );

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
