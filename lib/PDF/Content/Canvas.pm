use v6;

use HTML::Canvas;
class PDF::Content::Canvas is HTML::Canvas {

    use PDF::Content::Ops :OpNames;

    method content {
        # stub
        [
         OpNames::SetStrokeRGB => [1.0, 0.5, 0.3],
         OpNames::Rectangle => [10, 10, 100, 50],
         OpNames::Stroke,
        ]
    }

}
