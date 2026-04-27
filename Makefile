.PHONY: all html pdf docx clean lint format

all:
	quarto render
	rm -rf docs/cv-*_files docs/index_files

html:
	quarto render --to html

pdf:
	quarto render --to typst

docx:
	quarto render --to docx

lint:
	Rscript -e "lintr::lint_dir('R/')"

format:
	air format R/

clean:
	rm -rf docs/cv-*.html docs/cv-*.pdf docs/cv-*.docx docs/cv-*_files docs/index.html docs/index_files
