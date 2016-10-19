use v6;

use HTML::Canvas;
class PDF::Content::Canvas is HTML::Canvas {

    use PDF::Content::Ops :OpCode;

    method content {
        # stub
        [
         OpCode::SetStrokeRGB => [1.0, 0.5, 0.3],
         OpCode::Rectangle => [10, 10, 100, 50],
         OpCode::Stroke,
        ]
    }

}
