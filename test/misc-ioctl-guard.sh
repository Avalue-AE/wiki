#!/bin/bash
# Builds the real hal_misc_ioctl() dispatch code -- sed-extracted verbatim
# from src/hal/ec/ite_misc.c, so a future edit to the dispatch loop is what
# this test grades, not a hand-copied reimplementation -- against each
# misc-capable board's own generated config.h, with the EC bus stubbed to
# count and record every register access. See test/README.md.
#
# Catches: an ioctl command number no channel defines (command 0 is the
# case that reached ESM-KX60G's EC register 0x4B, issue #62) must be
# rejected with -ENOTTY and touch no EC register -- not silently match a
# disabled slot or a channel's unset write command. Also checks a real
# channel's own read and write commands still dispatch correctly.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARDS_DIR="$REPO_ROOT/configs/boards"
CONFIG_SH="$REPO_ROOT/scripts/config.sh"
DISPATCH_SRC="$REPO_ROOT/src/hal/ec/ite_misc.c"
HARNESS_SRC="$REPO_ROOT/test/misc-ioctl-guard-harness.c"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/shim/linux"
cat > "$SCRATCH/shim/linux/types.h" <<'TYPES_EOF'
#ifndef __SHIM_LINUX_TYPES_H__
#define __SHIM_LINUX_TYPES_H__
typedef unsigned char u8;
typedef unsigned int u32;
typedef int s32;
#endif
TYPES_EOF

boards=$(grep -l '^MAKE_MISC_DEVICE=ec' "$BOARDS_DIR"/*.conf)
if [ -z "$boards" ]; then
    echo "[MISC-GUARD]: FAILED: no board sets MAKE_MISC_DEVICE=ec -- nothing to test."
    exit 1
fi

checked=0
failed_boards=()

for conf in $boards; do
    board=$(basename "$conf" .conf)
    bdir="$SCRATCH/$board"
    mkdir -p "$bdir/configs"

    if ! "$CONFIG_SH" "$conf" "$bdir/configs/config.h" >"$bdir/config.log" 2>&1; then
        echo "[MISC-GUARD]: FAILED: $board: scripts/config.sh could not build config.h"
        cat "$bdir/config.log"
        failed_boards+=("$board")
        continue
    fi

    {
        awk '/^#define MISC_CONFIG\(nr\)/{p=1} p{print; if ($0 !~ /\\$/) p=0}' "$DISPATCH_SRC"
        sed -n '/^struct hal_misc_config hal_misc_configs/,/^};/p' "$DISPATCH_SRC"
        sed -n '/^s32 hal_misc_read(/,/^}/p' "$DISPATCH_SRC"
        sed -n '/^s32 hal_misc_write(/,/^}/p' "$DISPATCH_SRC"
        sed -n '/^s32 hal_misc_ioctl(/,/^}/p' "$DISPATCH_SRC"
    } > "$bdir/dispatch.inc"

    if ! gcc -Wall -Wextra -Werror -Wno-unused-variable -Wno-unused-parameter -Wno-unused-but-set-variable \
        -I "$SCRATCH/shim" -I "$bdir" -I "$REPO_ROOT/src" \
        -o "$bdir/harness" "$HARNESS_SRC" 2>"$bdir/build.log"; then
        echo "[MISC-GUARD]: FAILED: $board: harness build error"
        cat "$bdir/build.log"
        failed_boards+=("$board")
        continue
    fi

    board_failed=0
    for case in undefined channel0-read channel0-write; do
        out=$("$bdir/harness" "$case")
        rc=$?
        echo "[MISC-GUARD]: $board: $out"
        if [ "$rc" -eq 0 ]; then
            checked=$((checked + 1))
        else
            board_failed=1
        fi
    done
    if [ "$board_failed" -eq 1 ]; then
        failed_boards+=("$board")
    fi
done

board_count=$(echo "$boards" | wc -l)
echo "[MISC-GUARD]: $checked case(s) run across $board_count board(s)."

if [ "$checked" -eq 0 ]; then
    echo "[MISC-GUARD]: FAILED: zero cases run -- that is a broken run, not a pass."
    exit 1
fi
if [ "${#failed_boards[@]}" -gt 0 ]; then
    echo "[MISC-GUARD]: FAILED: ${#failed_boards[@]} board(s) had a failing case: ${failed_boards[*]}"
    exit 1
fi

echo "[MISC-GUARD]: PASS: all $board_count board(s) clean."
exit 0
