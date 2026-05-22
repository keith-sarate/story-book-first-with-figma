#!/usr/bin/env bash
# Build the article PDFs from their markdown sources.
#
# Sources live in article/ and use two separate toolchains, both fetched via
# npx on demand (cached locally after the first run):
#   - md-to-pdf + article.css  → storybook-first-with-figma.pdf (long-form article)
#   - @marp-team/marp-cli      → presentation.pdf (slide deck)
#
# Requires: Node 18+ and network access on the first run (cache reused after).
#
# Usage:
#   scripts/build-pdfs.sh              # build both
#   scripts/build-pdfs.sh article      # build only the article
#   scripts/build-pdfs.sh presentation # build only the deck
#   scripts/build-pdfs.sh clean        # remove generated PDFs

set -euo pipefail

# Resolve repo root from this script's location (so it works from any cwd).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTICLE_DIR="${REPO_ROOT}/article"

build_article() {
  echo "▸ Building storybook-first-with-figma.pdf"
  (cd "$ARTICLE_DIR" && npx --yes md-to-pdf --stylesheet article.css storybook-first-with-figma.md)
}

build_presentation() {
  echo "▸ Building presentation.pdf"
  (cd "$ARTICLE_DIR" && npx --yes @marp-team/marp-cli presentation.md --pdf --allow-local-files)
}

clean() {
  rm -f "${ARTICLE_DIR}/storybook-first-with-figma.pdf" "${ARTICLE_DIR}/presentation.pdf"
  echo "✓ Cleaned generated PDFs"
}

case "${1:-pdfs}" in
  pdfs|"")        build_article && build_presentation ;;
  article)        build_article ;;
  presentation)   build_presentation ;;
  clean)          clean ;;
  -h|--help|help)
    sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's|^# \?||'
    ;;
  *)
    echo "Unknown target: $1" >&2
    echo "Usage: scripts/build-pdfs.sh [pdfs|article|presentation|clean]" >&2
    exit 1
    ;;
esac
