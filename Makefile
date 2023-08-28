DocProj=pdf-raku.github.io
DocRepo=https://github.com/pdf-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku
TEST_JOBS ?= 6

all : doc

test :
	@prove -e"raku -I ." -j $(TEST_JOBS) t

loudtest :
	@prove -e"raku -I ." -v t

clean :
	@rm -f docs/PDF/Content.md docs/PDF/Content/*.md docs/PDF/Content/*/*.md

$(DocLinker) :
	(cd .. && git clone $(DocRepo) $(DocProj))

docs/%.md : lib/%.rakumod
	@raku -I. -c $<
	raku -I . --doc=Markdown $< \
	|  TRAIL=$* raku -p -n $(DocLinker) \
        > $@

Pod-To-Markdown-installed :
	@raku -M Pod::To::Markdown -c

doc : $(DocLinker) Pod-To-Markdown-installed docs/index.md docs/PDF/Content.md docs/PDF/Content/Canvas.md docs/PDF/Content/Ops.md docs/PDF/Content/Image.md docs/PDF/Content/Font/CoreFont.md docs/PDF/Content/Text/Box.md docs/PDF/Content/Color.md docs/PDF/Content/Tag.md docs/PDF/Content/PageTree.md docs/PDF/Content/Text/Box.md docs/PDF/Content/Text/Style.md

docs/index.md : README.md
	cp $< $@


