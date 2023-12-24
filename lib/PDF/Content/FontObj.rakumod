#| Interface role for PDF::Content compatible font objects:
unit role PDF::Content::FontObj;

=begin pod
=head2 Description

This role is consumed by font object implmentations, include:

=item PDF::Content::CoreFont

=item  PDF::Font::Loader::FontObj

=end pod

method font-name {...}   # font name, including XXXXXX+ prefix for subsetted fonts
method height {...}      # computed font height
method stringwidth {...} # computed with of a string
method encode {...}      # encode text to buffer
method decode {...}      # decode buffer to text
method kern {...}        # kern text
method to-dict {...}     # create a PDF Font dictionary
method cb-finish {...}   # finish the font. e.g. embed and create CMaps and Widths
# todo: is-subset is-core-font is-embedded underline-position underline-thickness lock type encoding encode-cids units-per-EM
