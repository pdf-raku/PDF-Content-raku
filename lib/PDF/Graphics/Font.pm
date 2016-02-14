use v6;

role PDF::Graphics::Font {

    has $.font-obj is rw handles <encode decode filter height kern stringwidth>;

}
