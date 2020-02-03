use v6;

unit class PDF::Content::Tag;

use PDF::COS;
use PDF::COS::Dict;
use Method::Also;

has Str $.name is required;
has Str $.op;
has %.attributes;
has Bool $.is-new is rw;  # tags not yet in the struct tree
has PDF::Content::Tag $.parent is rw; # hierarchical parent
our class Set {...}
has Set $.kids handles<AT-POS list grep map tags children> .= new;

#| See [PDF 32000 Tables 333 - Standard structure types for grouping elements]
my enum StructureTags is export(:StructureTags,:Tags) (
    :Document<Document>, :Part<Part>, :Article<Art>, :Section<Sect>,
    :Division<Div>, :BlockQuotation<BlockQuote>, :Caption<Caption>,
    :TableOfContents<TOC>, :TableOfContentsItem<TOCI>, :Index<Index>,
    :NonstructuralElement<NonStruct>, :PrivateElement<Private>,
);

#| See [PDF 32000 Tables 334-337 - Block-level structure elements]
my enum ParagraphTags is export(:ParagraphTags,:Tags) (
    :Paragraph<P>, :Header<H>,   :Header1<H1>,
    :Header2<H2>,  :Header3<H3>, :Header4<H4>,
    :Header5<H5>,  :Header6<H6>,
);
my enum ListElemTags is export(:ListElemTags,:Tags) (
    :List<L>, :ListItem<LI>, :Label<Lbl>, :ListBody<LBody>,
);
my enum TableTags is export(:TableTags,:Tags) (
    :Table<Table>,  :TableRow<TR>,     :TableHeader<TH>,
    :TableData<TD>, :TableBody<TBody>, :TableFooter<TFoot>, 
);

#| See [PDF 32000 Table 338 - Standard structure types for inline-level structure elements]
my enum InlineElemTags is export(:InlineElemTags,:Tags) (
    :Span<Span>, :Quotation<Quote>, :Note<Note>, :Reference<Reference>,
    :BibliographyEntry<BibEntry>, :Code<Code>, :Link<Link>,
    :Annotation<Annot>,
    :Ruby<Ruby>, :RubyPunctutation<RP>, :RubyBaseText<RB>, :RubyText<RT>,
    :Warichu<Warichu>, :WarichuPunctutation<RP>, :WarichuText<RT>,
    :Artifact<Artifact>,
);

my enum IllustrationTags is export(:IllusttrationTags,:Tags) (
    :Figure<Figure>, :Forumla<Formula>, :Form<Form>
);

constant %TagAliases is export(:TagAliases) = %( StructureTags.enums, ParagraphTags.enums, ListElemTags.enums, TableTags.enums, InlineElemTags.enums, IllustrationTags.enums );
constant TagSet is export(:TagSet) = %TagAliases.values.Set;

method add-kid(PDF::Content::Tag $kid) {
    $!kids.push: $kid;
    $kid.parent = self;
}

method !attributes-gist {
    given %!attributes {
        my %a = $_;
        %a<MCID> = $_ with self.?mcid;
        %a.pairs.sort.map({ " {.key}=\"{.value}\"" }).join: '';
    }
}

method gist {
    my $attributes = self!attributes-gist();
    $.kids
        ?? [~] flat("<{$.name}$attributes>",
                    $!kids.map(*.gist),
                    "</{$.name}>")
        !! "<{$.name}$attributes/>";
}

method build-struct-elem(PDF::COS::Dict :parent($P)!, :%nums) {

    my $elem = PDF::COS.coerce: %(
        :Type( :name<StructElem> ),
        :S( :$!name ),
        :$P,
    );

    my @k = $.kids.build-struct-elems($elem, :%nums);
    if @k {
        $elem<K> = @k > 1 ?? @k !! @k[0];
    }

    if %!attributes {
        $elem<A> = PDF::COS.coerce: :dict(%!attributes);
    }

    $elem;
}

method take-descendants {
    take self;
    $!kids.take-descendants;
}
method descendant-tags { gather self.take-descendants }

method build-struct-tree {
    .build-struct-tree
        given PDF::Content::Tag::Set.new: :tags[self];
}

our class Set {

    my subset Node where PDF::Content::Tag | Str;
    has Node @.tags handles<grep map AT-POS Bool shift push elems>;
    method  children { @!tags }
    method take-descendants { @!tags.grep(PDF::Content::Tag).map(*.take-descendants) }
    method descendant-tags { gather self.take-descendants }

    method build-struct-elems($parent, |c) {
        [ @!tags.map(*.build-struct-elem(:$parent, |c)).grep(*.defined) ];
    }

    method build-struct-tree {
        my PDF::COS::Dict $struct-tree = PDF::COS.coerce: { :Type( :name<StructTreeRoot> ) };
        my @Nums;

        if @!tags {
            my UInt %nums{Any};
            my @k = @.build-struct-elems($struct-tree, :%nums);
            if @k {
                $struct-tree<K> = +@k > 1 ?? @k !! @k[0];
            }
            if %nums {
                my $n = 0;
                for %nums.sort {
                    my $parent := .key;
                    @Nums.push: $n;
                    @Nums.push: $parent;
                    $n += .value;
                }
                $struct-tree<ParentTree> = %( :@Nums );
            }
        }

        ($struct-tree, @Nums);
    }

    method gist { @!tags.map(*.gist).join }
}
