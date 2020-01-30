use v6;

# top-level content-related PDF actions as performed by PDF::Class
# and PDF::Lite 
unit role PDF::Content::Interface;

# I/O
method open { ... }
method update { ... }
method save-as { ... }
method Root {...}
# pages
method Pages {...}
method page {...}
method add-page {...}
method delete-page {...}
method insert-page {...}
method page-count {...}
method rotate { ... }
# media boxes
method media-box { ... }
method crop-box { ... }
method bleed-box { ... }
method trim-box { ... }
method art-box { ... }
# fonts
method core-font { ... }
method use-font { ... }
