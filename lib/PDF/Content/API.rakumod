#| top-level content-related PDF actions as performed by PDF::Class,
#| PDF::Lite (and PDF::API6)
unit role PDF::Content::API;

use PDF::Content::Interface;
also does PDF::Content::Interface;

use PDF::Content::Font::CoreFont;

has PDF::Content::Font::CoreFont::Cache $!cache .= new;
method core-font(|c) {
    PDF::Content::Font::CoreFont.load-font(:$!cache, |c);
}
