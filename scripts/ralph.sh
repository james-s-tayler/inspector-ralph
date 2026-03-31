#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
TOOL="claude"
MAX_ITERATIONS=50
PROMPT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool)
            TOOL="$2"
            shift 2
            ;;
        --prompt)
            PROMPT_FILE="$2"
            shift 2
            ;;
        *)
            MAX_ITERATIONS="$1"
            shift
            ;;
    esac
done

if [[ -z "$PROMPT_FILE" ]]; then
    echo "Usage: ralph.sh --prompt <path-to-CLAUDE.md> [--tool amp|claude] [max_iterations]"
    exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Prompt file not found: $PROMPT_FILE"
    exit 1
fi

echo "Ralph starting: tool=$TOOL, max_iterations=$MAX_ITERATIONS, prompt=$PROMPT_FILE"

for i in $(seq 1 "$MAX_ITERATIONS"); do
    echo ""
    echo "=== Iteration $i of $MAX_ITERATIONS ==="
    echo ""

    if [[ "$TOOL" == "amp" ]]; then
        OUTPUT=$(cat "$PROMPT_FILE" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
    else
        OUTPUT=$(claude --dangerously-skip-permissions --print < "$PROMPT_FILE" 2>&1 | tee /dev/stderr) || true
    fi

    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "Ralph completed all tasks!"
        exit 0
    fi

    echo ""
    echo "Iteration $i complete. Continuing..."
    sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing."
exit 1
