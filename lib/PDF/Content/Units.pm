module PDF::Content::Units {

    sub postfix:<pt>($pt) is export( :length, :ALL) { $pt }
    sub postfix:<pc>($pc) is export( :length, :ALL) { $pc * 12 }
    sub postfix:<px>($px) is export( :length, :ALL) { $px * .75 }
    sub postfix:<in>($in) is export( :length, :ALL) { $in * 72 }
    sub postfix:<mm>($mm) is export( :length, :ALL) { $mm * 2.8346 }
    sub postfix:<cm>($cm) is export( :length, :ALL) { $cm * 28.346 }

}
