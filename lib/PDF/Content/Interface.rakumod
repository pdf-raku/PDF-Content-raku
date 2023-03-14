#| deprecated - use PDF::Content::API;
unit role PDF::Content::Interface;

# I/O
method open { ... }
method update { ... }
method save-as { ... }
method encrypt { ... }
## method is-encrypted { ... }
method Root {...}
method Str { ... }
method Blob { ... }
method ast { ... }

# page tree
method Pages {...}
method page {...}
method add-page {...}
method delete-page {...}
method insert-page {...}
method page-count {...}
method rotate { ... }
method iterate-pages { ... }

# media boxes
method media-box { ... }
method crop-box { ... }
method bleed-box { ... }
method trim-box { ... }
method art-box { ... }
method bleed { ... }

# fonts
method use-font { ... }
