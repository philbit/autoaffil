# Changelog

All notable changes to the `autoaffil` package will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Version numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
adapted to the LaTeX package convention (`v<major>.<minor>`).

---

## [v1.0] — 2026-06-06

Initial public release.

### Added

- `\autoauthor[extra]{Name}` — declare an author with optional extra superscript
  symbols (e.g.\ `*`, `\dagger`).
- `\autoaffil{text}` — attach an affiliation to the most recently declared author;
  identical strings are deduplicated automatically across the full author list.
- `\autoremark{symbol}{text}` — define a special remark (equal contribution,
  corresponding author, etc.).
- `\printauthors`, `\printaffils`, `\printremarks` — manual-placement commands.
- Automatic injection of the complete author/affiliation/remarks block into
  `\maketitle` via the `\@author`/`\parbox` strategy; compatible with any
  document class whose `\@maketitle` typesets `\@author`.
- Package option `ranges` — compress runs of three or more consecutive
  affiliation numbers into an en-dash range (e.g.\ `1--3`).
- Package option `superaftercomma` — place superscripts after the inter-author
  comma (revtex4-2 style) rather than before it.
- Package option `nobreak` — wrap each author-name+superscript unit in `\mbox{}`
  to prevent mid-entry line breaks.
- Package option `manual` — suppress auto-insertion; user places blocks manually.
- Customisation hooks: `\aafauthorfont`, `\aafauthorsep`, `\aafauthorspace`.
