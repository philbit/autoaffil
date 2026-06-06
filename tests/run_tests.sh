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

    # Extract text for content checks
    local text
    text=$(pdftotext "${name}.pdf" - 2>/dev/null)

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
run_test test-basic "basic: authors, affiliations, deduplication" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Carol Chen" \
    "CONTAINS:State University" \
    "CONTAINS:National Lab"

run_test test-dedup "deduplication: shared affiliations get one number" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Shared Institute"

run_test test-ranges "ranges option: 3+ consecutive numbers compress" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Inst A" \
    "CONTAINS:Inst B" \
    "CONTAINS:Inst C"

run_test test-superaftercomma "superaftercomma: comma before superscript" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown"

run_test test-nobreak "nobreak: compiles cleanly with mbox wrapping" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown"

run_test test-manual "manual mode: explicit \\printauthors etc." \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Institute One" \
    "CONTAINS:Institute Two"

run_test test-notes "addnote: symbols and text appear" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Equal contribution" \
    "CONTAINS:Corresponding"

run_test test-combined "combined options: ranges+superaftercomma+nobreak" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown" \
    "CONTAINS:Carol Chen"

run_test test-customhooks "custom aafauthorfont/sep/space" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown"

run_test test-singleauthor "single author (no separators, no trailing comma)" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Only Institute"

run_test test-noaffil "author with no affiliation" \
    "CONTAINS:Alice Anderson" \
    "CONTAINS:Bob Brown"

run_test test-extramarks "extra superscript marks only (no affiliation)" \
    "CONTAINS:Alice Anderson"

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
