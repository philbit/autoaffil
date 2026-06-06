# autoaffil — Automatic affiliation numbering for LaTeX

`autoaffil` is a LaTeX package for the author/affiliation layout style
used in physics and related fields: all authors appear in a single block with superscript numbers linking
each name to a list of affiliations printed below — the style native to
`revtex4-2` with the `superscriptaddress` option, and familiar from
journals such as Physical Review Letters.

The package brings this style to the standard `article` class and
compatible classes, with automatic deduplication: authors and
affiliations are declared individually in the preamble; identical
affiliation strings are automatically assigned the same number; numbers
are assigned in order of first appearance; and `\maketitle` outputs the
complete author/affiliation/notes block without any further effort.

## Quick start

```latex
\documentclass{article}
\usepackage[ranges,superaftercomma]{autoaffil}

\autoauthor{Alice Anderson}
  \autoaffil{MIT, Cambridge MA}
  \autoaffil{Princeton University}
\autoauthor[*]{Bob Brown}
  \autoaffil{MIT, Cambridge MA}   % deduplicated — same number as Alice's MIT
  \autoaffil{CERN, Geneva}
\autoauthor[*,\dagger]{Carol Chen}
  \autoaffil{CERN, Geneva}        % deduplicated
\autoremark{*}{Equal contribution.}
\autoremark{\dagger}{Corresponding author: \texttt{carol@example.com}}

\title{My Paper}
\date{\today}

\begin{document}
\maketitle
\section{Introduction}
...
\end{document}
```

With `[superaftercomma]` the comma precedes the superscript; affiliation
numbers come first, then any extra symbols. The output looks like:

<blockquote>
<b>Alice Anderson</b>,<sup>1,2</sup>&ensp;<b>Bob Brown</b>,<sup>1,3,∗</sup>&ensp;<b>Carol Chen</b><sup>3,∗,†</sup>
<br><br>
<sup>1</sup>&thinsp;MIT, Cambridge MA<br>
<sup>2</sup>&thinsp;Princeton University<br>
<sup>3</sup>&thinsp;CERN, Geneva<br>
<br>
<sup>∗</sup>&thinsp;Equal contribution.<br>
<sup>†</sup>&thinsp;Corresponding author: carol@example.com
</blockquote>

## Installation

### From CTAN (recommended)

`autoaffil` is distributed through CTAN at
[`macros/latex/contrib/autoaffil`](https://ctan.org/pkg/autoaffil).
Once it is picked up by TeX Live and/or MiKTeX, no manual installation
is needed:

```
# TeX Live
tlmgr install autoaffil
```

MiKTeX installs packages on-the-fly on first use; alternatively, use the
MiKTeX Console to install `autoaffil` manually.

### Manual installation

1. Obtain `autoaffil.sty` by running `latex autoaffil.ins` to extract it
   from `autoaffil.dtx` (or `make unpack` in the repo root).
2. Place `autoaffil.sty` somewhere LaTeX can find it — for a single
   project, the same directory as your `.tex` file is fine; for a
   system-wide install, place it in your local `texmf` tree under
   `tex/latex/autoaffil/`.

## Usage

### Preamble declarations

```latex
\usepackage[<options>]{autoaffil}

\autoauthor[<extra>]{Author Name}
%   Declare an author. The optional argument <extra> is a comma-separated
%   list of math-mode symbols to append as extra superscripts, e.g. *
%   or \dagger. Order of \autoauthor calls determines the output order.

\autoaffil{Affiliation text}
%   Attach an affiliation to the most recently declared author. Repeat
%   for each affiliation. Identical strings (exact match) are
%   automatically given the same number.

% Tip: predefine affiliations as commands to guarantee string identity
% and keep each affiliation text in one place:
\newcommand{\MIT}{\autoaffil{MIT, Cambridge MA}}
\newcommand{\CERN}{\autoaffil{CERN, Geneva}}
% Then: \autoauthor{Alice} \MIT \CERN

\autoremark{<symbol>}{<text>}
%   Define a special remark. <symbol> is math-mode content (*, \dagger,
%   \ddagger, …). \printremarks outputs them in definition order.
```

### Package options

| Option | Effect |
|--------|--------|
| `ranges` | Compress runs of 3+ consecutive affiliation numbers to `n--m`; pairs and singles are unchanged. |
| `superaftercomma` | Place superscripts *after* the inter-author comma (revtex4-2 style) rather than before it. |
| `nobreak` | Wrap each name+superscript unit in `\mbox{}` to prevent mid-entry line breaks; inter-author spaces remain breakable. |
| `manual` | Suppress automatic insertion into `\maketitle`; use `\printauthors`, `\printaffils`, `\printremarks` manually. |

Options may be freely combined:

```latex
\usepackage[ranges,superaftercomma,nobreak]{autoaffil}
```

### In the document

**Auto mode** (default): just call `\maketitle` as normal. The package
injects the author block automatically.

**Manual mode** (`[manual]` option): call `\maketitle` for the title and
date, then place the blocks yourself:

```latex
\maketitle
\printauthors   % bold author list with superscripts
\printaffils    % numbered affiliation list
\printremarks     % special remarks (only if \autoremark was called)
```

### Customisation

Redefine any of these after `\usepackage{autoaffil}`:

```latex
\renewcommand\aafauthorfont[1]{\textit{#1}}   % italicise names instead of bold
\renewcommand\aafauthorsep{;}                  % semicolons between authors
\renewcommand\aafauthorspace{\quad}            % wider inter-author space
```

| Hook | Default | Effect |
|------|---------|--------|
| `\aafauthorfont{name}` | `\textbf{name}` | Formatting applied to each author name |
| `\aafauthorsep` | `,` | Separator between author entries |
| `\aafauthorspace` | `\hspace{0.5em plus 0.2em minus 0.1em}` | Space between entries (must be breakable) |

## Compatibility

- Requires LaTeX2e and the `etoolbox` package (standard in any modern
  TeX distribution).
- **Auto mode** works with any document class whose `\@maketitle`
  typesets `\@author` — in practice essentially all standard, journal,
  and preprint classes.
- **Manual mode** (`\printauthors`, `\printaffils`, `\printremarks`) works
  with any document class whatsoever.
- **Deduplication** is based on exact string comparison, so affiliation
  strings must be spelled identically across authors. The recommended
  pattern is to predefine each affiliation as a command:
  ```latex
  \newcommand{\MIT}{\autoaffil{MIT, Cambridge MA}}
  ```
  This keeps each affiliation text in one place and makes typos
  impossible.

## Documentation

Full documentation is in `autoaffil.pdf`, built from `autoaffil.dtx`:

```bash
make doc
```

## Repository structure

```
autoaffil.dtx      documented source (single authoritative file)
autoaffil.ins      docstrip installer (run: latex autoaffil.ins)
Makefile           build, test, and CTAN archive targets
tests/             regression test suite
CHANGELOG.md       version history
LICENSE            LPPL 1.3c
```

`autoaffil.sty` and `autoaffil.pdf` are generated files (not tracked in
git). Run `make unpack` and `make doc` (or just `make all`) to produce them.

## Contributing

Contributions are welcome — bug reports, suggestions, and pull requests
alike. Please open an issue or a PR on GitHub.

### How the source is organised

The single authoritative source file is **`autoaffil.dtx`**, which
combines the user documentation and the annotated implementation. The
other key files are derived from it:

| Derived file | How to regenerate |
|---|---|
| `autoaffil.sty` | `make unpack` (or `latex autoaffil.ins`) |
| `autoaffil.pdf` | `make doc` (runs `pdflatex autoaffil.dtx` three times) |

**Important:** always edit `autoaffil.dtx` (the macrocode sections in
the Implementation chapter), then regenerate `autoaffil.sty` with
`make unpack`. `autoaffil.sty` is a generated file — edits to it
directly will be lost on the next `make unpack`.

### Running the tests

```bash
make test
```

This compiles the twelve `.tex` files in `tests/` and checks the
extracted PDF text for expected content using `pdftotext`. All tests
should pass before opening a pull request. To add a new test, create
`tests/test-<name>.tex` and add a `run_test` line to
`tests/run_tests.sh` with the strings you expect to find in the output.

### Rebuilding from scratch

```bash
make distclean   # remove all generated files
make all         # extract autoaffil.sty + build autoaffil.pdf
make test        # run regression tests
```

### CTAN releases

Official releases on CTAN are produced by the maintainer using `make ctan`, which
creates a flat `autoaffil.zip` archive containing `autoaffil.dtx`, `autoaffil.ins`,
`autoaffil.pdf`, `README.md`, and `CHANGELOG.md`. This archive is uploaded directly
to CTAN at [`macros/latex/contrib/autoaffil`](https://ctan.org/pkg/autoaffil). No
separate `.tds.zip` is submitted — CTAN and TeX Live handle the TDS installation
from the flat archive automatically, and a separate TDS zip is discouraged for
small, straightforward packages.

---

## License

Copyright (C) 2026 Philip Bittihn.

This work may be distributed and/or modified under the conditions of
the [LaTeX Project Public License](https://www.latex-project.org/lppl/),
either version 1.3c or (at your option) any later version.

Maintainer: Philip Bittihn &lt;philip@bittihn.de&gt;
