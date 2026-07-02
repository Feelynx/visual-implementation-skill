#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: run-scenario.sh <scenario-file> [--model MODEL] [--grader-model MODEL] [--keep] [--no-grade] [--dry-run]

  <scenario-file>         path to a scenario markdown file (see tests/README.md)
  --model MODEL           model for the agent under test (default: sonnet)
  --grader-model MODEL    model for the grader call (default: sonnet)
  --keep                  do not delete the sandbox; print its path
  --no-grade              skip grading; exit 0 after printing the transcript
  --dry-run               print parsed header/prompt/rubric only; no sandbox, no calls
EOF
  exit 1
}

# Prints each trimmed comma-separated item of $1 on its own line.
csv_items() {
  printf '%s' "$1" | awk -v RS=',' '{
    gsub(/^[ \t\n]+|[ \t\n]+$/, "", $0)
    if (length($0) > 0) print
  }'
}

# Extracts a header field ("Name: value") from $HEADER_BLOCK.
get_field() {
  printf '%s\n' "$HEADER_BLOCK" | awk -v pat="^$1:" '
    $0 ~ pat {
      line = $0
      sub(pat, "", line)
      sub(/^[ \t]+/, "", line)
      print line
      exit
    }
  '
}

# Extracts the body of "## $1" up to (not including) the next "## " heading or EOF.
extract_section() {
  awk -v sec="## $1" '
    $0 == sec { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$SCENARIO_FILE"
}

MODEL="sonnet"
GRADER_MODEL="sonnet"
KEEP=0
NO_GRADE=0
DRY_RUN=0
SCENARIO_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --model)
      [ $# -ge 2 ] || { echo "Error: --model requires a value" >&2; usage; }
      MODEL="$2"; shift 2 ;;
    --grader-model)
      [ $# -ge 2 ] || { echo "Error: --grader-model requires a value" >&2; usage; }
      GRADER_MODEL="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --no-grade) NO_GRADE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    -*) echo "Error: unknown option: $1" >&2; usage ;;
    *)
      [ -z "$SCENARIO_FILE" ] || { echo "Error: unexpected argument: $1" >&2; usage; }
      SCENARIO_FILE="$1"; shift ;;
  esac
done

[ -n "$SCENARIO_FILE" ] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

[ -f "$REPO_ROOT/visual-implementation/SKILL.md" ] || {
  echo "Error: $REPO_ROOT/visual-implementation/SKILL.md not found (is REPO_ROOT correct?)" >&2
  exit 1
}
[ -f "$SCENARIO_FILE" ] || {
  echo "Error: scenario file not found: $SCENARIO_FILE" >&2
  exit 1
}
SCENARIO_FILE="$(cd "$(dirname "$SCENARIO_FILE")" && pwd)/$(basename "$SCENARIO_FILE")"

HEADER_BLOCK="$(awk '/^## /{exit} {print}' "$SCENARIO_FILE")"

TYPE="$(get_field 'Type')"
FIXTURES_RAW="$(get_field 'Fixtures')"
EXPECTED_FILES_RAW="$(get_field 'Expected-Files')"
ALLOWED_TOOLS="$(get_field 'Allowed-Tools')"
[ -n "$ALLOWED_TOOLS" ] || ALLOWED_TOOLS="Read,Glob,Grep,Skill"

# NOTE: section bodies are never captured via "$(...)" — command substitution
# unconditionally strips trailing newlines, which would silently eat a
# trailing blank line in the source section and break verbatim extraction.
# extract_section is instead piped/redirected directly wherever its output
# is needed.

if [ "$DRY_RUN" -eq 1 ]; then
  echo "=== PARSED HEADER ==="
  echo "Type: $TYPE"
  echo "Fixtures: $FIXTURES_RAW"
  echo "Expected-Files: $EXPECTED_FILES_RAW"
  echo "Allowed-Tools: $ALLOWED_TOOLS"
  echo "Model: $MODEL"
  echo "Grader-Model: $GRADER_MODEL"
  echo "=== PROMPT ==="
  extract_section 'Prompt'
  echo "=== END PROMPT ==="
  echo "=== RUBRIC ==="
  extract_section 'Expected'
  echo "=== END RUBRIC ==="
  exit 0
fi

command -v claude >/dev/null 2>&1 || {
  echo "Error: 'claude' CLI not found on PATH. Install: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
}

TMP="$(mktemp -d)"
cleanup() {
  if [ "$KEEP" -eq 1 ]; then
    echo "Sandbox kept at: $TMP"
  else
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT

mkdir -p "$TMP/.claude/skills"
cp -R "$REPO_ROOT/visual-implementation" "$TMP/.claude/skills/visual-implementation"

if [ -n "$FIXTURES_RAW" ]; then
  mkdir -p "$TMP/fixtures"
  while IFS= read -r f; do
    SRC="$REPO_ROOT/tests/$f"
    [ -f "$SRC" ] || { echo "Error: fixture not found: $SRC" >&2; exit 1; }
    cp "$SRC" "$TMP/fixtures/"
  done < <(csv_items "$FIXTURES_RAW")
fi

PROMPT_FILE="$TMP/.prompt.txt"
extract_section 'Prompt' > "$PROMPT_FILE"

# Prompt is piped via stdin rather than passed as an argv string: this makes
# byte-for-byte reproduction of backticks/quotes/$vars in the prompt a
# non-issue (no argv re-quoting) while still matching claude -p's documented
# "read prompt from stdin" mode.
if ! ( cd "$TMP" && claude -p --model "$MODEL" --allowedTools "$ALLOWED_TOOLS" < "$PROMPT_FILE" > "$TMP/transcript.md" 2> "$TMP/stderr.log" ); then
  echo "Error: claude -p (agent under test) failed" >&2
  cat "$TMP/stderr.log" >&2 || true
  exit 1
fi

echo "=== TRANSCRIPT ==="
cat "$TMP/transcript.md"
echo "=== TRANSCRIPT ==="

if [ "$NO_GRADE" -eq 1 ]; then
  exit 0
fi

GRADER_PROMPT_FILE="$TMP/.grader-prompt.txt"
{
  cat <<'GRADERINSTR'
You are grading an agent transcript against a rubric. For each rubric item output PASS/FAIL with a one-line reason. Then output exactly one final line: `VERDICT: PASS` only if every required item passed and no forbidden behavior occurred, else `VERDICT: FAIL`.
GRADERINSTR
  echo
  echo "=== RUBRIC ==="
  extract_section 'Expected'
  echo
  echo "=== TRANSCRIPT ==="
  cat "$TMP/transcript.md"
  echo

  if [ -n "$EXPECTED_FILES_RAW" ]; then
    while IFS= read -r ef; do
      SRC="$REPO_ROOT/tests/$ef"
      [ -f "$SRC" ] || { echo "Error: expected-file not found: $SRC" >&2; exit 1; }
      echo "--- GROUND TRUTH: $ef ---"
      cat "$SRC"
      echo
    done < <(csv_items "$EXPECTED_FILES_RAW")
  fi
} > "$GRADER_PROMPT_FILE"

# Run from an empty, isolated directory (not $TMP) so the grader never sees
# the skill or fixtures — it must judge the transcript on its own.
NEUTRAL_DIR="$(mktemp -d)"
if ! ( cd "$NEUTRAL_DIR" && claude -p --model "$GRADER_MODEL" < "$GRADER_PROMPT_FILE" > "$TMP/grade.md" 2> "$TMP/grade-stderr.log" ); then
  echo "Error: claude -p (grader) failed" >&2
  cat "$TMP/grade-stderr.log" >&2 || true
  rm -rf "$NEUTRAL_DIR"
  exit 1
fi
rm -rf "$NEUTRAL_DIR"

echo "=== GRADE ==="
cat "$TMP/grade.md"
echo "=== GRADE ==="

LAST_VERDICT="$(grep '^VERDICT:' "$TMP/grade.md" | tail -n1 || true)"
case "$LAST_VERDICT" in
  *PASS*) exit 0 ;;
  *) exit 2 ;;
esac
