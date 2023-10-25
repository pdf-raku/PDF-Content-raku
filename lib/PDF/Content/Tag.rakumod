#| Tagged and marked content
unit class PDF::Content::Tag;

=begin pod

=head2 Description

This class assists in the detection or construction of tagged and
marked content in page or xobject form content streams:

=head2 Example

=begin code :lang<raku>
use lib 't';
use PDFTiny;
use PDF::Content::XObject;
use PDF::Content::Tag :ParagraphTags, :IllustrationTags;

my PDFTiny $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $pdf.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {
    my PDF::Content::Tag $tag;

    $tag = $gfx.mark: Header1, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    say $tag.name.Str; # 'H1'
    say $tag.mcid;     # marked content id of 0

    $tag = $gfx.mark: Paragraph, {
        .say('Paragraph that contains a figure', :position[50, 100], :font($body-font), :font-size(12));

        # nested tag. Note: marks cannot be nested, but tags can
        .tag: Figure, {
            my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";
            .do: $img, :position[50,70];
        }

    }

    say $tag.name.Str;         # 'P'
    say $tag.mcid;             # marked content id of 1
    say $tag.kids[0].name.Str; # 'Figure'
}

say $page.gfx.tags.gist; # '<H1 MCID="0"/><P MCID="1"><Figure/></P>';
=end code

=head2 Methods

=end pod

use PDF::COS;
use PDF::COS::Array;
use PDF::COS::Dict;
use PDF::COS::Stream;

our class NodeSet {...}

has Str $.name is rw;
has Str $.op;
has %.attributes;
has $.canvas is required;
method owner is DEPRECATED<canvas> { $!canvas }
has UInt $.start is rw;
has UInt $.end is rw;
has UInt $.mcid is rw; # marked content identifer
has PDF::COS::Stream $.content;
has PDF::Content::Tag $.parent is rw; # hierarchical parent
has NodeSet $.kids handles<AT-POS list grep map tags children elems> .= new;

#| See [PDF 32000 Tables 333 - Standard structure types for grouping elements]
my enum StructureTags is export(:StructureTags,:Tags) (
    :Document<Document>, :Part<Part>, :Article<Art>, :Section<Sect>,
    :Division<Div>, :BlockQuotation<BlockQuote>, :Caption<Caption>,
    :TableOfContents<TOC>, :TableOfContentsItem<TOCI>, :Index<Index>,
    :NonStructural<NonStruct>, :Private<Private>,
    # + [PDF 32000-2 Table 365 — Grouping level structure types]
    :DocumentFragment<DocumentFragment>, :Aside<Aside>, :Subdivision<Sub>,
);

#| See [PDF 32000 Tables 334-337 - Block-level structure elements]
my enum ParagraphTags is export(:ParagraphTags,:Tags) (
    :Paragraph<P>, :Header<H>,
    :Header1<H1>,  :Header2<H2>,  :Header3<H3>,
    :Header4<H4>,  :Header5<H5>,  :Header6<H6>,
    # + [PDF 32000-2 Table 366 — Block level structure types]
    :Title<Title>, :FENote<FENote>,
);
my enum ListElemTags is export(:ListElemTags,:Tags) (
    :List<L>, :ListItem<LI>, :Label<Lbl>, :ListBody<LBody>,
);
my enum TableTags is export(:TableTags,:Tags) (
    :Table<Table>,     :TableHead<THead>, :TableBody<TBody>,
    :TableFoot<TFoot>, :TableHeader<TH>,  :TableRow<TR>,
    :TableData<TD>,
);

#| See [PDF 32000 Table 338 - Standard structure types for inline-level structure elements]
my enum InlineElemTags is export(:InlineElemTags,:Tags) (
    :Span<Span>, :Quotation<Quote>,   :Note<Note>, :Reference<Reference>,
    :BibliographyEntry<BibEntry>,     :CODE<Code>, :Link<Link>,
    :Annotation<Annot>, :Ruby<Ruby>,  :RubyPunctuation<RP>,
    :RubyBaseText<RB>,  :RubyText<RT>,
    :Warichu<Warichu>,  :WarichuPunctuation<RP>, :WarichuText<RT>,
    # + [PDF 32000-2 Table 368 — General inline level structure types]
    :Emphasis<Em>, :Strong<Strong>
);

my enum IllustrationTags is export(:IllustrationTags,:Tags) (
    :Figure<Figure>, :Formula<Formula>, :Form<Form>
);

#| These tags are meaningful within content streams, as opposed to the structure-tree
my enum ContentTags is export(:ContentTags,:Tags) (
    :Artifact<Artifact>,
    :OptionalContent<OC>,  # [PDF 32000 8.11.3.2 Optional Content in Content Streams]
    :TagSuspect<TagSuspect>, :ReversedChars<ReversedChars>, # [PDF 32000 14.8.2 Tagged PDF and Page Content]
    :Clipped<Clip>, # [PDF 32000 14.6.3 Marked Content and Clipping
);

constant %TagAliases is export(:TagAliases) = %( StructureTags.enums, ParagraphTags.enums, ListElemTags.enums, TableTags.enums, InlineElemTags.enums, IllustrationTags.enums, ContentTags.enums );
constant TagSet is export(:TagSet) = %TagAliases.values.Set;

#| Add a child tag
multi method add-kid(PDF::Content::Tag $kid --> PDF::Content::Tag) {
    die 'tag already parented by {.gist}' with $kid.parent;
    die "can't add tag to itself"
        if $kid === self;
    $!kids.push: $kid;
    $kid.parent = self;
    $kid;
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
        ?? [~] ("<{$.name}$attributes>",
                $!kids».gist.Slip,
                "</{$.name}>")
        !! "<{$.name}$attributes/>";
}

#| take self and all descendants
method take-descendants {
    take self;
    $!kids.take-descendants;
}

#| gather all descendants
method descendants returns Seq { gather self.take-descendants }

our class NodeSet {
    my subset Node where PDF::Content::Tag | Str;
    has Node @.tags handles<grep map AT-POS Bool shift push elems>;

    method children { @!tags }
    method take-descendants { @!tags.grep(PDF::Content::Tag).map(*.take-descendants) }
    method descendants { gather self.take-descendants }
    method gist { @!tags».gist.join }
}
