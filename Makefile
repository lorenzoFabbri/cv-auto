.PHONY: all html pdf docx clean lint format

all: html pdf docx

html:
	quarto render index.qmd --to html

pdf:
	quarto render index.qmd --to typst

docx:
	quarto render index.qmd --to docx

lint:
	Rscript -e "lintr::lint_dir('R/')"

format:
	air format R/

clean:
	rm -rf docs/index.html docs/index.pdf docs/index.docx docs/index_files
