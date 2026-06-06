# CTAN Initial Submission — v1.0 (2026-06-05)

Record of the information submitted to CTAN at https://ctan.org/upload
for the initial release of `autoaffil`. The full package description is
in `description.html`.

---

## Package identity

| Field | Value |
|---|---|
| Name | `autoaffil` |
| Version | `1.0` |
| Maintainer | Philip Bittihn |
| Uploader | Philip Bittihn |
| CTAN path | `macros/latex/contrib/autoaffil` |
| License | `lppl1.3c` — The LaTeX Project Public License 1.3c |

---

## Summary

```
Automatic deduplicated affiliation numbering for author blocks with footnote-style affiliations for article and related classes
```

---

## Communication channels

| Field | Value |
|---|---|
| Home page | https://github.com/philbit/autoaffil |
| Bug tracker | https://github.com/philbit/autoaffil/issues |
| Repository | https://github.com/philbit/autoaffil |

---

## Announcement

The following announcement was submitted with the initial upload and
published on the CTAN mailing list and RSS feed.

```
autoaffil is a new LaTeX package that provides the author/affiliation layout
style common in physics and related fields: all authors appear in a single
block with superscript numbers linking each name to a list of affiliations
printed below — the style native to revtex4-2 with the superscriptaddress
option, and familiar from journals such as Physical Review Letters.

The package brings this style to the standard article class and compatible
classes. Authors and affiliations are declared individually in the preamble;
identical affiliation strings are automatically deduplicated and numbered in
order of first appearance; \maketitle outputs the complete block.

Package options: ranges (compress 3+ consecutive numbers to n--m),
superaftercomma (revtex4-2-style comma placement), nobreak (prevent line
breaks within name+superscript units), and manual (suppress auto-insertion
for full placement control). The only dependency is etoolbox.
```
