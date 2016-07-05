use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content;
use PDF::Content::Text::Block;
use PDF::Content::Util::Font;

plan 1;

my $font = PDF::Content::Util::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $text = "Hello. Ting, ting, ting. Attention! … ATTENTION!";
role Parent {
    has $!key = 'Ft0';
    has Str %!keys{Any};

    method use-resource($obj) {
	my $key = ++ $!key;
	self<Font>{$key} = $obj;
	%!keys{$obj} = $key;
	$obj;
    }
    method resource-key($obj) {
	$.use-resource($obj)
	unless %!keys{$obj}:exists;
	%!keys{$obj};
    }
    method resource-entry($a,$b) {
	self{$a}{$b};
    }
}
my $parent = {} does Parent;
my $text-block = PDF::Content::Text::Block.new( :$text, :$font, :$font-size );

my $gfx = PDF::Content.new( :$parent );

$gfx.say( $text-block );
$gfx.print( $text-block );

is-json-equiv [ $gfx.ops ], [
    :BT[],
    :Tf[:name<Ft1>, :real(16)],
    :TL[:real(17.6)],
    :TJ[ :array[:literal("Hello. Ting, ting, ting. Attention! \x[85] ATTENTION!")] ],
    'T*' => [],
    :ET[],
    :BT[],
    :TJ[ :array[:literal("Hello. Ting, ting, ting. Attention! \x[85] ATTENTION!")] ],
    :ET[],
    ], 'simple text block';
