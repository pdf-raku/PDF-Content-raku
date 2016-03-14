use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Basic;
use PDF::Basic::Text::Block;
use PDF::Basic::Util::Font;

plan 1;

my $font = PDF::Basic::Util::Font::core-font( :family<helvetica>, :weight<bold> );
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
my $text-block = PDF::Basic::Text::Block.new( :$text, :$font, :$font-size );

my $gfx = PDF::Basic.new( :$parent );

$gfx.print( $text-block );

is-json-equiv [ $gfx.ops ], [ :BT[],
                              :Tf[:name<Ft1>, :real(16)],
                              :TL[:real(17.6)],
                              :TJ[ :array[:literal("Hello. Ting, ting, ting. Attention! \x[85] ATTENTION!")] ],
                              :ET[],
    ], 'simple text block';
