#!/usr/bin/env bash
# run_tests.sh — Regression test runner for the autoaffil package.
#
# Usage: bash run_tests.sh  (from the tests/ directory)
#        make test          (from the repo root)
#
# Each test compiles a .tex file and verifies:
#   1. pdflatex exits with status 0
#   2. No "!" error lines in the log
#   3. Expected strings appear in the extracted text (via pdftotext)
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Allow overriding the path to autoaffil.sty (default: ../autoaffil.sty)
STYDIR="${STYDIR:-..}"
export TEXINPUTS="${STYDIR}:${TEXINPUTS:-}"

PASS=0
FAIL=0
ERRORS=()

run_test() {
    local name="$1"       # test name (without .tex)
    local desc="$2"       # human-readable description
    shift 2
    # Remaining arguments: pairs of "CONTAINS:<string>" or "ABSENT:<string>"

    printf "  %-36s ... " "$name ($desc)"

    # Compile (suppress output; capture log)
    if ! pdflatex -interaction=nonstopmode -halt-on-error "${name}.tex" \
            > /dev/null 2>&1; then
        echo "FAIL [pdflatex error]"
        FAIL=$((FAIL+1))
        ERRORS+=("$name: pdflatex returned non-zero")
        return
    fi

    # Check for LaTeX errors in the log
    if grep -qE '^!' "${name}.log" 2>/dev/null; then
        echo "FAIL [! in log]"
        FAIL=$((FAIL+1))
        ERRORS+=("$name: error lines in log")
        return
    fi

    # Extract text for content checks.
    # text:      line-by-line (for CONTAINS/ABSENT — within-line matches)
    # text_flat: newlines collapsed to single spaces (for INLINE/INLINEABSENT —
    #            checks that cross line boundaries, e.g. "1 State University"
    #            where the affiliation number and its text land on separate lines)
    local text text_flat
    text=$(pdftotext "${name}.pdf" - 2>/dev/null)
    text_flat=$(echo "$text" | tr '\n' ' ' | tr -s ' ')

    local failed=0
    for check in "$@"; do
        local kind="${check%%:*}"
        local needle="${check#*:}"
        case "$kind" in
            CONTAINS)
                if ! echo "$text" | grep -qF "$needle"; then
                    echo "FAIL [missing: $needle]"
                    failed=1
                    ERRORS+=("$name: expected '$needle' not found in PDF text")
                fi
                ;;
            ABSENT)
                if echo "$text" | grep -qF "$needle"; then
                    echo "FAIL [unexpected: $needle]"
                    failed=1
                    ERRORS+=("$name: '$needle' should not appear in PDF text")
                fi
                ;;
            INLINE)
                if ! echo "$text_flat" | grep -qF "$needle"; then
                    echo "FAIL [missing inline: $needle]"
                    failed=1
                    ERRORS+=("$name: expected '$needle' not found in collapsed PDF text")
                fi
                ;;
            INLINEABSENT)
                if echo "$text_flat" | grep -qF "$needle"; then
                    echo "FAIL [unexpected inline: $needle]"
                    failed=1
                    ERRORS+=("$name: '$needle' should not appear in collapsed PDF text")
                fi
                ;;
        esac
        [ "$failed" -eq 1 ] && break
    done

    if [ "$failed" -eq 0 ]; then
        echo "PASS"
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
    fi
}

echo ""
echo "autoaffil regression tests"
echo "=========================="
echo ""

# ---------------------------------------------------------------------------
# Checks beyond bare name/affil presence are marked with what they verify.

# Deduplication: State Univ=1, Nat Lab=2, Tech Inst=3.
# Alice gets 1,2; Bob gets deduped 1 (not a new 4th entry); Carol gets deduped 2 and new 3.
# INLINE checks verify the affiliation list assigns the correct numbers.
run_test test-basic "basic: authors, affiliations, deduplication" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Carol Chen" \
    "CONTAINS:State University" \
    "CONTAINS:National Lab" \
    "CONTAINS:Tech Institute" \
    "CONTAINS:Alice Anderson1,2" \
    "CONTAINS:Bob Brown1 ," \
    "CONTAINS:Carol Chen2,3" \
    "INLINE:1 State University" \
    "INLINE:2 National Lab" \
    "INLINE:3 Tech Institute"

# All three authors share one affiliation -> only one affiliation entry (number 1).
# INLINE checks verify the list has exactly one numbered entry.
run_test test-dedup "deduplication: shared affiliations get one number" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Carol Chen" \
    "CONTAINS:Shared Institute" \
    "CONTAINS:Bob Brown1 ," \
    "CONTAINS:Carol Chen1" \
    "INLINE:1 Shared Institute" \
    "INLINEABSENT:2 Shared"

# Alice has affiliations 1,2,3 -> compressed to 1–3.  Bob has 1,3 -> stays 1,3.
# INLINE checks confirm Inst A=1 and Inst C=3 (pdftotext order is reliable for these two).
run_test test-ranges "ranges option: 3+ consecutive numbers compress" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Inst A" \
    "CONTAINS:Inst B" \
    "CONTAINS:Inst C" \
    "CONTAINS:1–3" \
    "CONTAINS:Bob Brown1,3" \
    "ABSENT:1,2,3" \
    "INLINE:1 Inst A" \
    "INLINE:3 Inst C"

# Comma appears immediately after the author name, before the superscript.
run_test test-superaftercomma "superaftercomma: comma before superscript" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Anderson,1" \
    "ABSENT:Anderson1 ,"

# nobreak wraps name+super in \mbox{}; line-break behaviour is not pdftotext-checkable.
run_test test-nobreak "nobreak: compiles cleanly with mbox wrapping" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Carol Chen"

# Manual mode: correct superscripts assigned; dedup works (Bob has 2,1 not 2,3).
run_test test-manual "manual mode: explicit \\printauthors etc." \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Institute One" \
    "CONTAINS:Institute Two" \
    "CONTAINS:Alice Anderson1 ," \
    "CONTAINS:Bob Brown2,1"

# Affiliation number appears before extra mark in superscript (1,∗ not ∗,1).
run_test test-notes "addnote: symbols and text appear" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Equal contribution" \
    "CONTAINS:Corresponding" \
    "CONTAINS:Alice Anderson1,∗" \
    "CONTAINS:bob@example.com"

# Options [ranges,superaftercomma,nobreak] combined with \addnote usage.
# Carol has affiliations 1,2,3 -> 1–3 under [ranges]; superaftercomma puts comma before super.
# INLINE checks confirm MIT=1 and CERN=3 (pdftotext order is reliable for these two).
run_test test-combined "combined: [ranges,superaftercomma,nobreak] + \\addnote" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Carol Chen" \
    "CONTAINS:Carol Chen1–3" \
    "CONTAINS:Anderson,1,2," \
    "CONTAINS:bob@example.com" \
    "INLINE:1 MIT, Cambridge MA" \
    "INLINE:3 CERN, Geneva"

# Semicolon separator replaces the default comma.
run_test test-customhooks "custom aafauthorfont/sep/space" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Institute Two" \
    "CONTAINS:1 ;"

# Single author: superscript 1 present; no trailing separator after the name.
run_test test-singleauthor "single author (no separators, no trailing comma)" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Only Institute" \
    "CONTAINS:Alice Anderson1" \
    "ABSENT:Anderson1 ," \
    "INLINE:1 Only Institute"

# Alice has affil 1; Bob has no affiliation and must have no superscript.
run_test test-noaffil "author with no affiliation" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Alice Anderson1 ," \
    "ABSENT:Bob Brown1" \
    "INLINE:1 Institute One"

# Alice has only an extra mark (†), no affiliation number; Bob has affil 1.
run_test test-extramarks "extra superscript marks only (no affiliation)" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Alice Anderson†" \
    "CONTAINS:Bob Brown1" \
    "ABSENT:Alice Anderson1"

# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"

if [ "${#ERRORS[@]}" -gt 0 ]; then
    echo ""
    echo "Failures:"
    for e in "${ERRORS[@]}"; do
        echo "  - $e"
    done
    echo ""
    exit 1
fi

echo ""
