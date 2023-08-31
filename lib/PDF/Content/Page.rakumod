#| roles for a PDF Page dictionary
unit role PDF::Content::Page;

use PDF::Content::Canvas;
also does PDF::Content::Canvas;

use PDF::COS;
use PDF::COS::Tie;
use PDF::COS::Stream;
use PDF::Content::XObject;

my Array enum PageSizes is export(:PageSizes) «
        :Letter[0,0,612,792]
        :Tabloid[0,0,792,1224]
        :Ledger[0,0,1224,792]
        :Legal[0,0,612,1008]
        :Statement[0,0,396,612]
        :Executive[0,0,540,720]
        :A0[0,0,2384,3371]
        :A1[0,0,1685,2384]
        :A2[0,0,1190,1684]
        :A3[0,0,842,1190]
        :A4[0,0,595,842]
        :A5[0,0,420,595]
        :B4[0,0,729,1032]
        :B5[0,0,516,729]
        :Folio[0,0,612,936]
        :Quarto[0,0,610,780]
    »;

my subset Box of List is export(:Box) where {.elems == 4}

proto to-landscape($) is export(:to-landscape) {*}
#| e.g. $.to-landscape(PagesSizes::A4)
multi sub to-landscape(Box $p --> Box) {
    [ $p[1], $p[0], $p[3], $p[2] ]
}
#| e.g. $.to-landscape('A4')
multi sub to-landscape(Str $size --> Box) is hidden-from-backtrace {
    my Array $rect = PageSizes::{$size} // die "Unknown named page size '$size' (expected: {PageSizes::.keys.sort.join: ', '})";
    to-landscape($rect);
}

#! return a content stream for the page
method contents returns Str {
    with self<Contents> {
        my Array $streams = do {
            when List { $_ }
            when Hash { [$_] }
            default   { die "unexpected page content: {.raku}" }
        }
        $streams.keys.map({ $streams[$_].decoded }).join: '';
    }
    else {
        ''
    };
}

#| produce an XObject form for this page
method to-xobject($page = self, Array :$BBox = $page.trim-box.clone) {
    my %Resources;
    with $page.Resources -> $r {
        %Resources{$_} = $r{$_} for $r.keys;
    }
    # copy unflushed graphics
    my $xobject = self.xobject-form( :$BBox, :%Resources);
    $xobject.pre-gfx.ops($page.pre-gfx.ops);
    $xobject.gfx.ops($page.gfx.ops);

    # copy content streams
    if $page.contents -> $append {
        $xobject.edit-stream: :$append;
        # inherit compression from the first stream segment
        for $page<Contents>[0] {
            $xobject<Filter> = .clone
                with .<Filter>;
            $xobject<DecodeParms> = .clone
                with .<DecodeParms>;
        }
    }

    $xobject;
}

#| rw accessor for page contents
method decoded is rw {
    Proxy.new(
        FETCH => { self.contents },
        STORE => -> $, $decoded {
            if self<Contents> ~~ PDF::COS::Stream {
                self<Contents>.decoded = $decoded;
            }
            else {
                self<Contents> = PDF::COS::Stream.new: :$decoded;
            }
        },
    );
}

method cb-finish {
    self.MediaBox //= [0, 0, 612, 792];
    $.finish
}
