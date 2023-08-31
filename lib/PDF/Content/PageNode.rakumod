#| role for a page dictionary
unit role PDF::Content::PageNode;

use PDF::COS::Tie::Hash;
use PDF::Content::Page :PageSizes, :Box, :&to-landscape;
use PDF::Content::XObject :&from-origin;

my subset BoxOrStr where Box|Str;

method to-landscape(Box $p = self.bbox --> Box) {
    to-landscape($p);
}

my constant %BBoxEntry = %(
    :media<MediaBox>, :crop<CropBox>, :bleed<BleedBox>, :trim<TrimBox>, :art<ArtBox>
);
my subset BoxName of Str where %BBoxEntry{$_}:exists;

method !get-prop(BoxName $box) is rw {
    my $bbox = %BBoxEntry{$box};
    self."$bbox"();
}

method bbox(BoxName $box-name = 'media') is rw {
    my &FETCH := do given $box-name {
        when 'media' { -> $ { from-origin(self.MediaBox) // [0, 0, 612, 792] } }
        when 'crop'  { -> $ { from-origin(self.CropBox) // self.bbox('media') } }
        default      { -> $ { from-origin(self!get-prop($box-name)) // self.bbox('crop') } }
    };

    Proxy.new(
        :&FETCH,
        STORE => -> $, BoxOrStr $size {
            my $rect := $size ~~ Box
                ?? $size
                !! PageSizes::{$size} // fail "Unknown named page size '$size' (expected: {PageSizes::.keys.sort.join: ', '})";
            self!get-prop($box-name) = $rect;
        },
       );
}

method bleed is rw {
    my enum <lx ly ux uy>;
    Proxy.new(
        FETCH => {
            my @t[4] = $.bbox('trim');
            my @b[4] = $.bbox('bleed');
            @t[lx]-@b[lx], @t[ly]-@b[ly], @b[ux]-@t[ux], @b[uy]-@t[uy]; 
        },
        STORE => -> $, Array() $b is copy {
            my @t[4] = $.bbox('trim');

            $b[lx] //= 8.5;
            $b[ly] //= $b[lx];
            $b[ux] //= $b[lx];
            $b[uy] //= $b[ly];

            self.BleedBox = @t[lx]-$b[lx], @t[ly]-$b[ly], @t[ux]+$b[ux], @t[uy]+$b[uy];
        },
    );
}

method media-box(|c) is rw { self.bbox('media', |c) }
method crop-box(|c)  is rw { self.bbox('crop',  |c) }
method bleed-box(|c) is rw { self.bbox('bleed', |c) }
method trim-box(|c)  is rw { self.bbox('trim',  |c) }
method art-box(|c)   is rw { self.bbox('art',   |c) }

method width  { .[2] - .[0] given self.media-box }
method height { .[3] - .[1] given self.media-box }

