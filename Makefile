PACKAGE  = autoaffil
DTXFILE  = $(PACKAGE).dtx
INSFILE  = $(PACKAGE).ins
STYFILE  = $(PACKAGE).sty
PDFFILE  = $(PACKAGE).pdf

LATEX    = pdflatex
LATEX2   = latex
NONSTOP  = -interaction=nonstopmode
MKINDEX  = makeindex

.PHONY: all doc unpack test ctan tds clean distclean help

all: doc unpack

## Build the formatted documentation PDF (three passes for cross-references).
doc: $(PDFFILE)

$(PDFFILE): $(DTXFILE)
	$(LATEX) $(NONSTOP) $(DTXFILE)
	$(MKINDEX) -s gglo.ist -o $(PACKAGE).gls $(PACKAGE).glo
	$(MKINDEX) -s gind.ist -o $(PACKAGE).ind $(PACKAGE).idx
	$(LATEX) $(NONSTOP) $(DTXFILE)
	$(LATEX) $(NONSTOP) $(DTXFILE)

## Extract autoaffil.sty from autoaffil.dtx via docstrip.
## The .sty is removed first because docstrip refuses to overwrite.
unpack:
	rm -f $(STYFILE)
	$(LATEX2) $(NONSTOP) $(INSFILE)

## Run the regression test suite (unpacks first to ensure .sty is current).
test: unpack
	cd tests && bash run_tests.sh

## Create a flat CTAN upload archive: autoaffil.zip
## Contains: autoaffil.dtx, autoaffil.ins, autoaffil.pdf, README.md, CHANGELOG.md
## Note: a separate .tds.zip is NOT included — CTAN and TeX Live discourage
## TDS zips for small, straightforward packages.
ctan: doc unpack
	mkdir -p ctan/$(PACKAGE)
	cp $(DTXFILE) $(INSFILE) $(PDFFILE) README.md CHANGELOG.md ctan/$(PACKAGE)/
	cd ctan && zip -r ../$(PACKAGE).zip $(PACKAGE)
	rm -rf ctan
	@echo ""
	@echo "CTAN archive: $(PACKAGE).zip"

## Create a TDS-compliant zip.
## Not submitted to CTAN — included for reference only.
## CTAN and TeX Live discourage .tds.zip files for small, straightforward packages.
tds: doc unpack
	mkdir -p tds/tex/latex/$(PACKAGE)
	mkdir -p tds/doc/latex/$(PACKAGE)
	mkdir -p tds/source/latex/$(PACKAGE)
	cp $(STYFILE) tds/tex/latex/$(PACKAGE)/
	cp $(PDFFILE) README.md CHANGELOG.md tds/doc/latex/$(PACKAGE)/
	cp $(DTXFILE) $(INSFILE) tds/source/latex/$(PACKAGE)/
	cd tds && zip -r ../$(PACKAGE).tds.zip .
	rm -rf tds
	@echo ""
	@echo "TDS archive: $(PACKAGE).tds.zip"

## Remove LaTeX auxiliary files (keep generated .sty and .pdf).
clean:
	rm -f *.aux *.log *.out *.toc *.idx *.ind *.ilg *.glo *.gls *.hd \
	      *.glo2 *.fls *.fdb_latexmk *.synctex.gz
	cd tests && rm -f *.aux *.log *.out *.ppm *.png

## Remove all generated files including .sty and .pdf.
distclean: clean
	rm -f $(STYFILE) $(PDFFILE) $(PACKAGE).zip $(PACKAGE).tds.zip

help:
	@echo "Targets:"
	@echo "  all        build doc + extract .sty  (default)"
	@echo "  doc        build autoaffil.pdf"
	@echo "  unpack     extract autoaffil.sty from autoaffil.dtx"
	@echo "  test       run the regression test suite"
	@echo "  ctan       create autoaffil.zip for CTAN upload"
	@echo "  tds        create autoaffil.tds.zip (TDS layout; not submitted to CTAN)"
	@echo "  clean      remove auxiliary files"
	@echo "  distclean  remove all generated files"
