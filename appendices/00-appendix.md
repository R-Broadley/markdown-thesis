\newpage
\appendix\appendixpage
\setcounter{page}{1}

\renewcommand{\thepage}{A.~\arabic{page}}
\renewcommand{\thesection}{\Alph{chapter}}
\renewcommand{\chapter}[1]{%
    \refstepcounter{chapter}%
    \chaptermark{#1}%
    \refstepcounter{section}%
    \addcontentsline{toc}{section}{\protect\numberline{\thesection}#1}%
    \sectionmark{#1}%
    }

# Example Appendix

\includepdf[pages=-, frame,width=\textwidth,offset=19 0, pagecommand={\label{app:example}}]{doc/example-doc.pdf}

# Example Appendix 2

\includepdf[pages=-, frame,width=\textwidth,offset=19 0, pagecommand={\label{app:example2}}]{doc/example-doc.pdf}

