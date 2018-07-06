SHELL = /bin/sh

DOCXTEMPLATEDIRS = $(shell find templates/docx -mindepth 1 -maxdepth 2 -not -name ".*" -type d)
DOCXTEMPLATEDEPS = $(foreach dir, $(DOCXTEMPLATEDIRS), $(wildcard $(dir)/*))

SUBDIR = submission
DRAFTDIR = draft
SECYAML = section.yaml
CHAPYAML = chapter.yaml
SECTIONS = main.yaml $(filter-out README.md $(wildcard appendices/*.md), $(sort $(wildcard *.md) $(wildcard */*.md)))
APPENDICIES = $(patsubst %.md,%.tex.md,$(filter-out $(wildcard appendices/*.tex.md), $(sort $(wildcard appendices/*.md))))
APPENDICIESARG = $(foreach app,$(APPENDICIES),--include-after-body $(app))
DEPS = thesis.bib $(wildcard fig/*.pdf) $(wildcard fig/*.png) $(wildcard fig/*.jpg)
DRAFTCHAPDEPS = chapter.yaml $(DEPS) $(DRAFTDIR)
DRAFTSECDEPS = section.yaml $(DEPS) $(DRAFTDIR)
MAINDEPS = main.yaml $(DEPS) university-logo.png $(SUBDIR) $(wildcard appendices/*.pdf)
LATEXTEMPLATE = templates/template.latex
DOCXTEMPLATE = templates/template.docx


BASICPANDOC = pandoc -s --filter pandoc-crossref
tex_build = $(BASICPANDOC) --natbib --template=$(LATEXTEMPLATE)
docx_build = $(BASICPANDOC) --filter pandoc-citeproc --reference-doc=$(DOCXTEMPLATE)
html_build = $(BASICPANDOC) --filter pandoc-citeproc --mathml


thesis: $(SUBDIR)/thesis.pdf

$(SUBDIR):
	mkdir -p $(SUBDIR)
	
$(DRAFTDIR):
	mkdir -p $(DRAFTDIR)

appendices/%.tex.md:
	(cd appendices && make)

$(SUBDIR)/thesis.pdf: thesis.tex $(DEPS)
	sed -i 's/citep{/cite{/g' $<
	sed -i 's/citeyearpar{/cite{/g' $<
	-pdflatex -interaction=batchmode -output-directory=$(SUBDIR) $<
	-bibtex $(basename $@)
	-pdflatex -interaction=batchmode -output-directory=$(SUBDIR) $<
	-pdflatex -interaction=batchmode -output-directory=$(SUBDIR) $<
	rm -f $< $(foreach ext, aux bbl blg lof log lot out toc, $(SUBDIR)/thesis.$(ext))

thesis.tex: $(SECTIONS) $(MAINDEPS) $(LATEXTEMPLATE) $(APPENDICIES)
	$(tex_build) $(APPENDICIESARG) -o $@ $(SECTIONS)

$(DOCXTEMPLATE): $(DOCXTEMPLATEDEPS)
	(cd templates/docx && \
	find . -mindepth 1 -maxdepth 2 -not -name ".*" \
	-exec zip -r template.docx {} \; && \
	mv template.docx ../)

$(DRAFTDIR)/thesis.docx: $(SECTIONS) $(MAINDEPS) $(DOCXTEMPLATE) $(DRAFTDIR)
	$(docx_build) -o $@ $(SECTIONS)

$(DRAFTDIR)/thesis.html: $(SECTIONS) $(MAINDEPS) $(DRAFTDIR)
	$(html_build) -o $@ $(SECTIONS)

$(DRAFTDIR)/%.pdf: %.tex $(DEPS)
	sed -i 's/citep{/cite{/g' $<
	sed -i 's/citeyearpar{/cite{/g' $<
	mkdir -p $(DRAFTDIR)/$(dir $<)
	-pdflatex -interaction=batchmode -output-directory=$(DRAFTDIR)/$(dir $<) $<
	-bibtex $(basename $@)
	-pdflatex -interaction=batchmode -output-directory=$(DRAFTDIR)/$(dir $<) $<
	-pdflatex -interaction=batchmode -output-directory=$(DRAFTDIR)/$(dir $<) $<
	rm -f $< $(foreach ext, aux bbl blg lof log lot out toc, $(DRAFTDIR)/$(basename $<).$(ext))

%.tex: % $(DRAFTCHAPDEPS) $(LATEXTEMPLATE)
	$(tex_build) -o $@ $(CHAPYAML) $</*.md

%.tex: %.md $(DRAFTSECDEPS) $(LATEXTEMPLATE)
	$(tex_build) -o $@ $(SECYAML) $<
	
$(DRAFTDIR)/%.docx: % $(DRAFTCHAPDEPS) $(DOCXTEMPLATE)
	$(docx_build) -o $@ $(CHAPYAML) $</*.md

$(DRAFTDIR)/%.docx: %.md $(DRAFTSECDEPS) $(DOCXTEMPLATE)
	mkdir -p $(DRAFTDIR)/$(dir $<)
	$(docx_build) -o $@ $(SECYAML) $<

$(DRAFTDIR)/%.html: % $(DRAFTCHAPDEPS)
	$(html_build) -o $@ $(CHAPYAML) $</*.md

$(DRAFTDIR)/%.html: %.md $(DRAFTSECDEPS)
	mkdir -p $(DRAFTDIR)/$(dir $<)
	$(html_build) -o $@ $(SECYAML) $<

clean:
	(cd appendices && make clean)
	find $(DRAFTDIR) -maxdepth 2 -name *.pdf -exec rm {} \;
	find $(DRAFTDIR) -maxdepth 2 -name *.docx -exec rm {} \;
	find $(DRAFTDIR) -maxdepth 2 -name *.html -exec rm {} \;
	find $(DRAFTDIR) -empty -type d -delete
