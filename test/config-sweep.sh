#!/bin/bash
# Hands every configs/boards/*.conf to scripts/config.sh -- the same guard a
# real build already runs for whichever one board it targets, run here for
# every board file a build might target. See test/README.md.
#
# This never touches src/configs/board.h: each run's generated header goes
# into a scratch directory removed at the end, so the tree is unchanged.
# It needs no kernel tree and runs no compiler -- scripts/config.sh alone
# decides pass or fail.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARDS_DIR="$REPO_ROOT/configs/boards"
CONFIG_SH="$REPO_ROOT/scripts/config.sh"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

names=0
declare -A seen_files
failed_boards=()
pairs_total=0
notgradable_total=0

for conf in "$BOARDS_DIR"/*.conf; do
    names=$((names + 1))
    real=$(readlink -f "$conf")
    seen_files["$real"]=1
    name=$(basename "$conf" .conf)
    out="$SCRATCH/${name}.h"
    log=$("$CONFIG_SH" "$conf" "$out" 2>&1)
    rc=$?
    # A not-gradable map is non-fatal in scripts/config.sh (rc stays 0), so
    # it must be surfaced here regardless of pass/fail or it goes quiet.
    echo "$log" | grep '^\[CONFIG\]: Note:'
    if [ "$rc" -ne 0 ]; then
        failed_boards+=("$name")
        echo "$log" | grep '^\[CONFIG\]: Error:'
        continue
    fi
    while read -r n; do
        [ -z "$n" ] && continue
        pairs_total=$((pairs_total + n))
    done < <(echo "$log" | grep -oE 'Verified [0-9]+' | grep -oE '[0-9]+')
    while read -r n; do
        [ -z "$n" ] && continue
        notgradable_total=$((notgradable_total + n))
    done < <(echo "$log" | grep -oE '\([0-9]+ not gradable\)' | grep -oE '[0-9]+')
done

files=${#seen_files[@]}

echo "[SWEEP]: $names board name(s) read in configs/boards/, resolving to $files distinct file(s)."
echo "[SWEEP]: $pairs_total _NUM/_MAP pair(s) compared, $notgradable_total not gradable."

if [ "${#failed_boards[@]}" -gt 0 ]; then
    echo "[SWEEP]: FAILED: ${#failed_boards[@]} board(s): ${failed_boards[*]}"
    exit 1
fi

echo "[SWEEP]: PASS: all $names board name(s) clean."
exit 0
