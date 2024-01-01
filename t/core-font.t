use v6;
use Test;
plan 60;
use lib 't/lib';
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Font;
use PDF::Content::Font::CoreFont;
use Font::AFM;
use PDFTiny;

is PDF::Content::Font::CoreFont.core-font-name('Helvetica,Bold'), 'helvetica-bold', 'core-font-name';
is PDF::Content::Font::CoreFont.core-font-name('Helvetica-BoldOblique'), 'helvetica-boldoblique', 'core-font-name';
is PDF::Content::Font::CoreFont.core-font-name('Arial,Bold'), 'helvetica-bold', 'core-font-name';
is-deeply PDF::Content::Font::CoreFont.core-font-name('Blah'), Nil, 'core-font-name';

my PDF::Content::Font::CoreFont $tr-bold .= load-font( :family<Times-Roman>, :weight<bold>);
is $tr-bold.font-name, 'Times-Bold', 'font-name';

my PDF::Content::Font::CoreFont $tsym .= load-font( :family<Symbol>, :weight<bold>);
is $tsym.font-name, 'Symbol', 'font-name';
is $tsym.enc, 'sym', 'enc';
isa-ok $tsym.metrics, 'Font::AFM';
is $tsym.encode("A♥♣✔B"), "\x[A9]\x[A7]", '.encode(...) sanity';
is $tsym.decode("\x[A9]\x[A7]"), "♥♣", '.decode(...) sanity';
is-deeply $tsym.encoder.charset, (my UInt %{UInt} = '♥'.ord => 0xA9, '♣'.ord => 0xA7), 'charset';

my PDF::Content::Font::CoreFont $hb-afm .= load-font( 'Helvetica-Bold' );
isa-ok $hb-afm.metrics, 'Font::AFM';
is $hb-afm.font-name, 'Helvetica-Bold', 'font-name';
is $hb-afm.enc, 'win', '.enc';
is $hb-afm.height, 1190, 'font height';
is $hb-afm.height(:hanging), 925, 'font height hanging';
is-approx $hb-afm.height(12), 14.28, 'font height @ 12pt';
is-approx $hb-afm.height(12, :from-baseline), 11.544, 'font base-height @ 12pt';
is-approx $hb-afm.height(12, :hanging), 11.1, 'font hanging height @ 12pt';
is $hb-afm.encode("A✔B"), "AB", '.encode(...) sanity';
# - 'A' & 'B' are in the encoding scheme and font
# - '♥', '♣' are in the font, but not the encoding scheme
# - '✔' is in neither
is-deeply $hb-afm.encoder.charset, (my UInt %{UInt} = 'A'.ord => 'A'.ord, 'B'.ord => 'B'.ord), 'charset';
is-json-equiv $hb-afm.encoder.differences, (), 'differences';

my PDF::Content::Font::CoreFont $ab-afm .= load-font( 'Arial-Bold' );
isa-ok $ab-afm.metrics, 'Font::AFM';
is $ab-afm.font-name, 'Helvetica-Bold', 'font-name';
is $ab-afm.encode("A♥♣✔B"), "AB", '.encode(...) sanity';

my PDF::Content::Font::CoreFont $hbi-afm .= load-font( :family<Helvetica>, :weight<Bold>, :style<Italic> );
is $hbi-afm.font-name, 'Helvetica-BoldOblique', ':font-family => font-name';

my PDF::Content::Font::CoreFont $hb-afm-again .= load-font( 'Helvetica-Bold' );
ok $hb-afm-again === $hb-afm, 'font caching';

my $ext-chars = "ΨΩαΩ";
my $enc = $hbi-afm.encode($ext-chars);
is $enc, "", "extended chars encoding";
is $hbi-afm.decode($enc), "",  "extended chars decoding";

$hbi-afm.cb-finish;
my $hbi-afm-dict = $hbi-afm.to-dict;
is-json-equiv $hbi-afm-dict, {
    :Type<Font>,
    :Subtype<Type1>,
    :BaseFont<Helvetica-BoldOblique>,
    :Encoding<WinAnsiEncoding>,
}, "to-dict (extended chars)";

my PDF::Content::Font::CoreFont $tr-afm .= load-font( 'Times-Roman' );
is $tr-afm.stringwidth("RVX", :!kern), 2111, 'stringwidth :!kern';
is $tr-afm.stringwidth("RVX", :kern), 2111 - 80, 'stringwidth :kern';
is-deeply $tr-afm.kern("RVX" ), (['R', -80, 'VX'], 2031), '.kern(...)';
is-deeply $tr-afm.shape("RVX" ), (['R', 80+0i, 'VX'], 2031), '.shape(...) kerning';
is-deeply $ab-afm.shape("first"), (["\x[1]r", 15+0i, 'st'], 1874), '.shape(...) ligatures';

for (win => "Á®ÆØ",
     mac => "ç¨®¯") {
    my ($enc, $encoded) = .kv;
    my $fnt = PDF::Content::Font::CoreFont.load-font( 'helvetica', :$enc );
    my $decoded = "Á®ÆØ";
    my $re-encoded = $fnt.encode($decoded);
    is-deeply $re-encoded, $encoded, "$enc encoding";
    is-deeply $fnt.decode($encoded), $decoded, "$enc decoding";
    is-deeply $fnt.decode($encoded, :ords), $decoded.ords, "$enc raw decoding";
}

my PDF::Content::Font::CoreFont $zapf .= load-font( 'ZapfDingbats' );
isa-ok $zapf.metrics, 'Font::Metrics::zapfdingbats';
is $zapf.enc, 'zapf', '.enc';
is $zapf.encode("♥♣✔"), "ª¨4", '.encode(...)'; # /a110 /a112 /a20
is $zapf.decode("ª¨4"), "♥♣✔", '.decode(...)';
is $zapf.decode("\o251\o252"), "♦♥", '.decode(...)';

isa-ok PDF::Content::Font::CoreFont.load-font('CourierNew,Bold').metrics, 'Font::Metrics::courier-bold';

my PDF::Content::Font::CoreFont $sym .= load-font( 'Symbol' );
isa-ok $sym.metrics, 'Font::Metrics::symbol';
is $sym.enc, 'sym', '.enc';
is $sym.encode("ΑΒΓ"), "ABG", '.encode(...)'; # /Alpha /Beta /Gamma
is $sym.decode("ABG"), "ΑΒΓ", '.decode(...)';

use Font::AFM;
use PDF::Content::Font::Enc::Type1;
my $metrics = Font::AFM.core-font('times-roman');
my @differences = [1, 'x', 'y', 10, 'a', 'b'];
my %glyphs = %Font::AFM::Glyphs.invert;
my PDF::Content::Font::Enc::Type1 $encoder .= new: :enc<win>, :%glyphs;
$encoder.differences = @differences;
my PDF::Content::Font::CoreFont $tr .= new: :$metrics, :$encoder;
is-deeply $tr.encode('abcxyz', :cids).list, (10,11,99,1,2,122), 'win differences encoding';
$tr.cb-finish;
is-json-equiv $tr.to-dict<Encoding><Differences>, [1, "x", "y", 10, "a", "b"], 'dfferences to-dict';

$encoder .= new: :enc<mac-extra>, :%glyphs;
$encoder.differences = @differences;
$tr .= new: :$metrics, :$encoder;
my $dec = 'abcxyz½';
$enc = buf8.new(10,11,3,1,2,4,72);
is-deeply $tr.encode($dec, :cids), $enc.list, 'mac-extra differences encoding';
is-deeply $tr.decode($enc.decode), $dec, 'mac-extra differences decoding';
$tr.cb-finish;
is-json-equiv $tr.to-dict<Encoding><Differences>, [1, "x", "y", "c", "z", 10, "a", "b"], 'dfferences to-dict';

my PDFTiny $pdf1 .= new;
my PDFTiny $pdf2 .= new;

my $tr1 = $pdf1.core-font('times-roman');
my $tr2 = $pdf2.core-font('times-roman');
is $tr1.font-name, 'Times-Roman';
ok $tr1 === $pdf1.core-font('times-roman'), 'PDF font caching';
ok $tr1 !=== $tr2, 'font uniqueness 1';
ok $tr1 !=== $pdf2.core-font('times-roman'), 'font uniqueness 2';

done-testing;
