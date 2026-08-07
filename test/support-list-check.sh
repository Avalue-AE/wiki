#!/bin/bash
# Proves scripts/support-list.sh really tracks configs/boards/*.conf and is
# not a fixed table: copies the real board files into a scratch directory,
# makes several targeted edits to the copy, runs the real script against
# that copy, and checks the *generated* output changed in exactly those
# ways. It also checks the committed table still matches what today's
# board files generate. See test/README.md.
#
# This never touches the committed configs/boards/ or docs/wiki/ -- every
# edit lands in a mktemp -d scratch directory removed when the run ends.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUPPORT_LIST_SH="$REPO_ROOT/scripts/support-list.sh"
BOARDS_DIR="$REPO_ROOT/configs/boards"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

SCRATCH_BOARDS="$SCRATCH/boards"
SCRATCH_OUT="$SCRATCH/Supported-Boards.md"
mkdir -p "$SCRATCH_BOARDS"
cp "$BOARDS_DIR"/*.conf "$SCRATCH_BOARDS"/

# (a) Flip one currently-"NOT HARDWARE-VALIDATED" board to
# "HARDWARE-VALIDATED", with a new date.
FLIP_BOARD="EMX-BYT2"
FLIP_DATE="2026-08-01"
if ! grep -q '^# STATUS: NOT HARDWARE-VALIDATED' "$SCRATCH_BOARDS/$FLIP_BOARD.conf"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: fixture assumption broken: $FLIP_BOARD.conf is not currently NOT HARDWARE-VALIDATED."
    exit 1
fi
sed -i "s/^# STATUS: NOT HARDWARE-VALIDATED\$/# STATUS: HARDWARE-VALIDATED (initial bench test $FLIP_DATE)/" \
    "$SCRATCH_BOARDS/$FLIP_BOARD.conf"

# (b) Add a new board that sets CONFIG_BOARD_NAME but none of the four
# MAKE_*_DEVICE keys.
NEW_BOARD="ZZZ-CHECK-NEWBOARD"
cat > "$SCRATCH_BOARDS/$NEW_BOARD.conf" <<EOF
# ================================
# $NEW_BOARD Board Configuration File (test fixture)
# ================================
CONFIG_BOARD_NAME="$NEW_BOARD"
EOF

# (c) Delete the "# STATUS:" line entirely from a third, still-unflipped
# NOT HARDWARE-VALIDATED board, leaving the rest of the file intact.
DELMARK_BOARD="ACP-BYT2C"
if ! grep -q '^# STATUS: NOT HARDWARE-VALIDATED' "$SCRATCH_BOARDS/$DELMARK_BOARD.conf"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: fixture assumption broken: $DELMARK_BOARD.conf is not currently NOT HARDWARE-VALIDATED."
    exit 1
fi
sed -i '/^# STATUS: NOT HARDWARE-VALIDATED$/d' "$SCRATCH_BOARDS/$DELMARK_BOARD.conf"
if grep -q '^# STATUS:' "$SCRATCH_BOARDS/$DELMARK_BOARD.conf"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: fixture assumption broken: $DELMARK_BOARD.conf still has a # STATUS: line after deletion."
    exit 1
fi

# (d) Symlink a fourth board file to a different board's real .conf, the
# way configs/boards/ADP-226-01.conf really points at ADP-226.conf. Its
# CONFIG_BOARD_NAME is its target's, not its own -- the row must still be
# named after this file's own name, not collapse into a duplicate of the
# board it links to.
SYMLINK_BOARD="ZZZ-CHECK-SYMLINK"
SYMLINK_TARGET="EMX-BYT2"
ln -s "$SYMLINK_TARGET.conf" "$SCRATCH_BOARDS/$SYMLINK_BOARD.conf"

# (e) Flip a fifth, still-untouched "NOT HARDWARE-VALIDATED" board to
# "HARDWARE-VALIDATED" with TWO dates on the same line -- a bench date and
# a retest date, the way a second bench pass really writes one. This must
# still read as one Markdown table row, and the `date` column is the
# first date only.
TWODATE_BOARD="ARC-ADLN"
TWODATE_BENCH="2026-07-07"
TWODATE_RETEST="2026-08-02"
if ! grep -q '^# STATUS: NOT HARDWARE-VALIDATED' "$SCRATCH_BOARDS/$TWODATE_BOARD.conf"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: fixture assumption broken: $TWODATE_BOARD.conf is not currently NOT HARDWARE-VALIDATED."
    exit 1
fi
sed -i "s/^# STATUS: NOT HARDWARE-VALIDATED\$/# STATUS: HARDWARE-VALIDATED (bench $TWODATE_BENCH, retest $TWODATE_RETEST)/" \
    "$SCRATCH_BOARDS/$TWODATE_BOARD.conf"

# ------------------------------------------------------------------------
# Run the real generator against the scratch copy.
# ------------------------------------------------------------------------
if ! run_log=$("$SUPPORT_LIST_SH" "$SCRATCH_BOARDS" "$SCRATCH_OUT" 2>&1); then
    echo "[SUPPORT-LIST-CHECK]: FAILED: scripts/support-list.sh exited non-zero."
    echo "$run_log"
    exit 1
fi
echo "$run_log"

if [ ! -f "$SCRATCH_OUT" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: expected output file not written: $SCRATCH_OUT"
    exit 1
fi

# ------------------------------------------------------------------------
# Grade the generated table itself -- every failure is named, nothing
# stops at the first one.
# ------------------------------------------------------------------------
failures=0
checked=0

flip_row=$(grep -E "^\| ${FLIP_BOARD} \|" "$SCRATCH_OUT" || true)
checked=$((checked + 1))
if [ -z "$flip_row" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: no row found for flipped board $FLIP_BOARD."
    failures=$((failures + 1))
elif ! echo "$flip_row" | grep -qE "\| *Yes *\| *${FLIP_DATE} *\|"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: flipped board $FLIP_BOARD did not turn Yes/$FLIP_DATE: $flip_row"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: flipped board $FLIP_BOARD now reads Yes / $FLIP_DATE."
fi

new_row=$(grep -E "^\| ${NEW_BOARD} \|" "$SCRATCH_OUT" || true)
checked=$((checked + 1))
if [ -z "$new_row" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: no row found for new board $NEW_BOARD."
    failures=$((failures + 1))
elif ! echo "$new_row" | grep -qE "^\| ${NEW_BOARD} \|  *\| No \|  *\|$"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: new board $NEW_BOARD did not get an empty driver cell: $new_row"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: new board $NEW_BOARD appeared with an empty driver cell."
fi

delmark_row=$(grep -E "^\| ${DELMARK_BOARD} \|" "$SCRATCH_OUT" || true)
checked=$((checked + 1))
if [ -z "$delmark_row" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: no row found for $DELMARK_BOARD (deleted marker)."
    failures=$((failures + 1))
elif ! echo "$delmark_row" | grep -qE "\| *No *\| *\|$"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: $DELMARK_BOARD with its # STATUS: line deleted did not read No: $delmark_row"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: $DELMARK_BOARD with its # STATUS: line deleted still reads No."
fi

symlink_row=$(grep -E "^\| ${SYMLINK_BOARD} \|" "$SCRATCH_OUT" || true)
checked=$((checked + 1))
if [ -z "$symlink_row" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: no row found for symlinked board $SYMLINK_BOARD -- it collapsed into its target's name instead of getting its own."
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: symlinked board $SYMLINK_BOARD got its own distinct row: $symlink_row"
fi

target_row_count=$(grep -cE "^\| ${SYMLINK_TARGET} \|" "$SCRATCH_OUT")
checked=$((checked + 1))
if [ "$target_row_count" -ne 1 ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: symlink target $SYMLINK_TARGET should have exactly 1 row, found $target_row_count."
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: symlink target $SYMLINK_TARGET still has exactly 1 row (not duplicated by its symlink)."
fi

twodate_row=$(grep -E "^\| ${TWODATE_BOARD} \|" "$SCRATCH_OUT" || true)
checked=$((checked + 1))
if [ -z "$twodate_row" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: no row found for two-date board $TWODATE_BOARD."
    failures=$((failures + 1))
elif ! echo "$twodate_row" | grep -qE "\| *Yes *\| *${TWODATE_BENCH} *\|\$"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: two-date board $TWODATE_BOARD did not read Yes / $TWODATE_BENCH (first date only): $twodate_row"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: two-date board $TWODATE_BOARD reads Yes / $TWODATE_BENCH, the first date only."
fi

checked=$((checked + 1))
if grep -qxF "${TWODATE_RETEST} |" "$SCRATCH_OUT"; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: the second date ($TWODATE_RETEST) leaked onto its own line, splitting the Markdown row."
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: the second date did not split the row."
fi

# ------------------------------------------------------------------------
# (f) A "# STATUS: PARTIALLY HARDWARE-VALIDATED" marker -- ESM-KX60G.conf
# carried it for nine days (4d9b747..f158962) -- must read `No` like any
# other unverified board, but be COUNTED as an explicit marker, not folded
# into "no marker": a partial marker is still a marker, and a reader must
# not be told "not even attempted" about a board that was. Proven by
# running the same one-board directory twice, with and without the line,
# and comparing the two runs' own summary counts.
# ------------------------------------------------------------------------
PARTIAL_BOARDS="$SCRATCH/partial-boards"
mkdir -p "$PARTIAL_BOARDS"
cat > "$PARTIAL_BOARDS/ZZZ-CHECK-PARTIAL.conf" <<EOF
CONFIG_BOARD_NAME="ZZZ-CHECK-PARTIAL"
# STATUS: PARTIALLY HARDWARE-VALIDATED (initial bench test 2026-07-07)
EOF

with_log=$("$SUPPORT_LIST_SH" "$PARTIAL_BOARDS" "$SCRATCH/partial-with.md" 2>&1)
with_explicit=$(printf '%s\n' "$with_log" | grep -oE 'No \(explicit\) [0-9]+' | grep -oE '[0-9]+$')
with_nomarker=$(printf '%s\n' "$with_log" | grep -oE 'No \(no marker\) [0-9]+' | grep -oE '[0-9]+$')

sed -i '/^# STATUS:/d' "$PARTIAL_BOARDS/ZZZ-CHECK-PARTIAL.conf"
without_log=$("$SUPPORT_LIST_SH" "$PARTIAL_BOARDS" "$SCRATCH/partial-without.md" 2>&1)
without_explicit=$(printf '%s\n' "$without_log" | grep -oE 'No \(explicit\) [0-9]+' | grep -oE '[0-9]+$')
without_nomarker=$(printf '%s\n' "$without_log" | grep -oE 'No \(no marker\) [0-9]+' | grep -oE '[0-9]+$')

partial_row=$(grep -E "^\| ZZZ-CHECK-PARTIAL \|" "$SCRATCH/partial-with.md" || true)
checked=$((checked + 1))
if [[ "$partial_row" != *"| No |"* ]]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: PARTIALLY HARDWARE-VALIDATED board did not read No: $partial_row"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: PARTIALLY HARDWARE-VALIDATED board reads No in its own row."
fi

checked=$((checked + 1))
if [ "$with_explicit" -eq $((without_explicit + 1)) ] && [ "$with_nomarker" -eq $((without_nomarker - 1)) ]; then
    echo "[SUPPORT-LIST-CHECK]: OK: PARTIALLY HARDWARE-VALIDATED is counted as an explicit marker, not folded into no-marker."
else
    echo "[SUPPORT-LIST-CHECK]: FAILED: PARTIALLY HARDWARE-VALIDATED not counted as explicit -- with marker: explicit=$with_explicit no-marker=$with_nomarker; without: explicit=$without_explicit no-marker=$without_nomarker."
    failures=$((failures + 1))
fi

# ------------------------------------------------------------------------
# (g) A device key with its chipset key left empty is a half-written
# block -- Makefile:99-103 warns and skips that subsystem rather than
# building it (proven live by ADP-226.conf: MAKE_WDT_DEVICE=ec,
# MAKE_WDT_CHIPSET= empty). The table must apply the same rule: the
# subsystem must not appear in the driver cell.
# ------------------------------------------------------------------------
HALFCHIP_BOARDS="$SCRATCH/halfchip-boards"
mkdir -p "$HALFCHIP_BOARDS"
cat > "$HALFCHIP_BOARDS/ZZZ-CHECK-HALFCHIP.conf" <<EOF
CONFIG_BOARD_NAME="ZZZ-CHECK-HALFCHIP"
MAKE_WDT_DEVICE=ec
MAKE_WDT_CHIPSET=
EOF

halfchip_log=$("$SUPPORT_LIST_SH" "$HALFCHIP_BOARDS" "$SCRATCH/halfchip.md" 2>&1)
halfchip_row=$(grep -E "^\| ZZZ-CHECK-HALFCHIP \|" "$SCRATCH/halfchip.md" || true)
checked=$((checked + 1))
if [ -z "$halfchip_row" ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: no row found for half-configured board ZZZ-CHECK-HALFCHIP."
    failures=$((failures + 1))
elif [[ "$halfchip_row" == *WDT* ]]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: ZZZ-CHECK-HALFCHIP has MAKE_WDT_DEVICE set but MAKE_WDT_CHIPSET empty -- the build skips WDT (Makefile:99-103) but the table still claims it: $halfchip_row"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: ZZZ-CHECK-HALFCHIP (device set, chipset empty) does not claim WDT, matching the build."
fi

# ------------------------------------------------------------------------
# (h) The committed docs/wiki/Supported-Boards.md must be exactly what
# today's real configs/boards/*.conf produce -- the file's own header says
# "do not hand-edit", and this is what actually enforces that.
# ------------------------------------------------------------------------
REAL_OUT="$REPO_ROOT/docs/wiki/Supported-Boards.md"
REGEN_OUT="$SCRATCH/Supported-Boards.regen.md"
checked=$((checked + 1))
if ! "$SUPPORT_LIST_SH" "$BOARDS_DIR" "$REGEN_OUT" >/dev/null 2>&1; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: scripts/support-list.sh exited non-zero regenerating the real table."
    failures=$((failures + 1))
elif ! diff_out=$(diff -u "$REAL_OUT" "$REGEN_OUT" 2>&1); then
    echo "[SUPPORT-LIST-CHECK]: FAILED: committed $REAL_OUT does not match what today's board files generate -- regenerate it with scripts/support-list.sh."
    echo "$diff_out"
    failures=$((failures + 1))
else
    echo "[SUPPORT-LIST-CHECK]: OK: committed $REAL_OUT is byte-identical to what today's board files generate."
fi

if [ "$failures" -gt 0 ]; then
    echo "[SUPPORT-LIST-CHECK]: FAILED: $failures of $checked check(s) failed."
    exit 1
fi

echo "[SUPPORT-LIST-CHECK]: PASS: all $checked check(s) confirmed the generator tracks the real board files."
exit 0
