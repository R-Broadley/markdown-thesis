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
DEPS = thesis.bib $(wildcard fig/*.pdf) $(wildcard fig/*.png) $(wildcard fig/*.jpg) $(wildcard $(wildcard *-appendices)/*.pdf)
DRAFTSECDEPS = section.yaml $(DEPS) $(DRAFTDIR)
MAINDEPS = main.yaml $(DEPS) university-logo.png $(SUBDIR)
LATEXTEMPLATE = templates/template.latex
DOCXTEMPLATE = templates/template.docx


BASICPANDOC = pandoc -s --filter pandoc-crossref --filter pandoc-citeproc
pdf_build = $(BASICPANDOC) --template=$(LATEXTEMPLATE)
docx_build = $(BASICPANDOC) --reference-doc=$(DOCXTEMPLATE)
html_build = $(BASICPANDOC) --mathml


thesis: $(SUBDIR)/thesis.pdf

$(SUBDIR):
	mkdir -p $(SUBDIR)
	
$(DRAFTDIR):
	mkdir -p $(DRAFTDIR)

appendices/%.tex.md:
	(cd appendices && make)

$(SUBDIR)/thesis.pdf: $(SECTIONS) $(MAINDEPS) $(LATEXTEMPLATE) $(APPENDICIES)
	$(pdf_build) $(APPENDICIESARG) -o $@ $(SECTIONS)

$(DOCXTEMPLATE): $(DOCXTEMPLATEDEPS)
	(cd templates/docx && \
	find . -mindepth 1 -maxdepth 2 -not -name ".*" \
	-exec zip -r template.docx {} \; && \
	mv template.docx ../)

$(DRAFTDIR)/thesis.docx: $(SECTIONS) $(MAINDEPS) $(DOCXTEMPLATE) $(DRAFTDIR)
	$(docx_build) -o $@ $(SECTIONS)

$(DRAFTDIR)/thesis.html: $(SECTIONS) $(MAINDEPS) $(DRAFTDIR)
	$(html_build) -o $@ $(SECTIONS)

$(DRAFTDIR)/%.pdf: % $(DRAFTSECDEPS) $(LATEXTEMPLATE)
	$(pdf_build) -o $@ $(CHAPYAML) $</*.md

$(DRAFTDIR)/%.pdf: %.md $(DRAFTSECDEPS) $(LATEXTEMPLATE)
	$(pdf_build) -o $$(sed "s/\//-/2g" <<< $@) $(SECYAML) $<
	
$(DRAFTDIR)/%.docx: % $(DRAFTSECDEPS) $(DOCXTEMPLATE)
	$(docx_build) -o $@ $(CHAPYAML) $</*.md

$(DRAFTDIR)/%.docx: %.md $(DRAFTSECDEPS) $(DOCXTEMPLATE)
	$(docx_build) -o $$(sed "s/\//-/2g" <<< $@) $(SECYAML) $<

$(DRAFTDIR)/%.html: % $(DRAFTSECDEPS)
	$(html_build) -o $@ $(CHAPYAML) $</*.md

$(DRAFTDIR)/%.html: %.md $(DRAFTSECDEPS)
	$(html_build) -o $$(sed "s/\//-/2g" <<< $@) $(SECYAML) $<

clean:
	(cd appendices && make clean)
	find $(DRAFTDIR) -maxdepth 1 -name *.pdf -exec rm {} \;
	find $(DRAFTDIR) -maxdepth 1 -name *.docx -exec rm {} \;
