main:
	pdflatex --shell-escape main.tex
	pybtex main
	pdflatex --shell-escape main.tex
	pdflatex --shell-escape main.tex
	rm -f *.out *.aux *.blg *.bbl *.toc *.nav *.snm

clean:
	rm -f *.out *.aux *.blg *.bbl *.toc *.nav *.snm
