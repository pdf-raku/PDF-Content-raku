use v6;

use PDF::Graphics::Contents;
use PDF::Graphics::Resourced;

role  PDF::Graphics::Page
    does PDF::Graphics::Resourced
    does PDF::Graphics::Contents {

    use PDF::DAO;
    use PDF::DAO::Tie;
    use PDF::DAO::Stream;

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

    #| contents may either be a stream on an array of streams
    method content-streams returns Array {
        given self<Contents> {
            when !.defined { [] }
            when Array     { $_ }
            when Hash      { [$_] }
            default { die "unexpected page content: {.perl}" }
        }
    }

    method contents returns Str {
	my $streams = $.content-streams;
	$streams.keys.map({ $streams[$_].decoded }).join: '';
    }

    #| produce an XObject form for this page
    method to-xobject($from = self, :$coerce, Array :$bbox = $from.trim-box) {

        my %dict = (
	    Type => :name<XObject>,
	    Subtype => :name<Form>,
	    Resources => $from.Resources.clone,
	    BBox => $bbox.clone,
	    );

        my $xobject = PDF::DAO.coerce( :stream{ :%dict });
	PDF::DAO.coerce($xobject, $coerce) if $coerce ~~ PDF::DAO::Tie;

	# copy unflushed graphics
        $xobject.pre-gfx.ops($from.pre-gfx.ops);
        $xobject.gfx.ops($from.gfx.ops);

	# copy content streams
	my Array $content-streams = $from.content-streams;
        $xobject.edit-stream: :append( [~] $content-streams.map: *.decoded );
        if +$content-streams {
            # inherit compression from the first stream segment
            for $content-streams[0] {
                $xobject<Filter> = .<Filter>.clone
                    if .<Filter>:exists;
                $xobject<DecodeParms> = .<DecodeParms>.clone
                    if .<DecodeParms>:exists;
            }
        }

        $xobject;
    }

    method cb-finish {

	self.MediaBox //= [0, 0, 612, 792];

	if ($.pre-gfx && $.pre-gfx.ops) || ($.gfx && $.gfx.ops) {
	    my $prepend = $.pre-gfx && $.pre-gfx.ops
		?? $.pre-gfx.content ~ "\n"
		!! '';

	    my $append = $.gfx && $.gfx.ops
		?? $.gfx.content
		!! '';

	    if self<Contents> ~~ PDF::DAO::Stream {
		self<Contents>.decoded = $prepend ~ $append;
	    }
	    else {
		self<Contents> = PDF::DAO::Stream.new( :decoded($prepend ~ $append) );
	    }
        }
    }

}
