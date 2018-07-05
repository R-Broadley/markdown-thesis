SHELL = /bin/sh

APPENDIXSOURCE = $(filter-out $(wildcard *.tex.md), $(wildcard *.md))
APPENDIXDEST = $(patsubst %.md,%.tex.md,$(APPENDIXSOURCE))
APPENDIXTEMP = $(patsubst %.md,%.tex,$(APPENDIXSOURCE))

appendices: $(APPENDIXDEST)

%.tex.md: %.md
	(pandoc --filter pandoc-crossref --filter pandoc-citeproc \
	--top-level-division=chapter -o $$(sed "s/.md//1g" <<< $@) $< && \
	mv $$(sed "s/.md//1g" <<< $@) $@)

clean:
	find -maxdepth 1 -name "*.tex.md" -exec rm {} \;
