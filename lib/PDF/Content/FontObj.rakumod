role PDF::Content::FontObj {

    # Interface role for PDF::Content compatible font objects. E.g.:
    # - PDF::Content::CoreFont
    # - PDF::Font::Loader::FreeType

    method font-name {...}   # font name, including XXXXXX+ prefix for subsetted fonts
    method height {...}      # computed font height
    method stringwidth {...} # computed with of a string
    method encode {...}      # encode text to buffer
    method decode {...}      # decode buffer to text
    method kern {...}        # kern text
    method to-dict {...}     # create a PDF Font dictionary
    method cb-finish {...}   # finish the font. e.g. embed and create CMaps and Widths

}
