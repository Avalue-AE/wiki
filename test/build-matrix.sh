#!/bin/bash

# Build every prepared kernel tree in $KERNELS_DIR against every board below,
# for every subsystem that board's .conf declares, and grade each build.
#
# Why grading is NOT "did make exit 0": the kernel trees under $KERNELS_DIR are
# stripped dev trees with no Module.symvers, so modpost there cannot resolve the
# kernel symbols an out-of-tree module imports. What that costs depends on the
# kernel, measured on this host: on all four 6.x trees (6.6.89, 6.8.2, 6.12.27,
# 6.14) modpost turns those symbols into "ERROR: modpost: ... undefined!" and
# make exits 2 even when the driver code is perfectly fine; on 5.15 the same
# symbols come out as "WARNING:" lines and make exits 0; on 5.4 modpost does not
# report them at all. That is a limitation of the dev tree, not of the driver. A
# checker that grades on $? would report every 6.x kernel as broken and get
# switched off within a week. So each build is graded on its output instead:
#   PASS = at least one "CC [M]" line, and zero lowercase "error:" lines
#   FAIL = zero "CC [M]" lines (Kbuild never reached the compiler), or any
#          "error:" line (a real compiler/Kbuild error)
# Kbuild uses -Wall -Wextra -Werror, so a warning already shows up as an
# "error:" line -- that is intended, do not filter it out.
#
# A second, separate source of trees: $KERNELS_CACHE_DIR (default
# /kernels-cache). $KERNELS_DIR is read-only on this host, so a tree fetched
# after the fact -- today, the only complete kernel 4.15 tree -- cannot be
# placed there and needs its own root. It is laid out as
# <name>/usr/src/linux-headers-*-generic/, the shape `dpkg-deb -x` produces
# for a fetched Ubuntu linux-headers-*-generic package; the exact suffix
# (e.g. -101) is part of that package's version and is globbed, not named.
#
# A cache tree is graded differently, two ways:
#   1. Built one subsystem at a time (make watchdog / gpio / hwmon / misc),
#      never a bare `make`. On kernel 4.15 a bare `make` (every subsystem the
#      board enables, in one invocation) fails on a KBUILD_MODNAME conflict
#      in a file the subsystems share -- a ruled, documented limitation (see
#      README's Supported Kernels section), not something to build around
#      with a different invocation shape for one kernel line.
#   2. Graded by produced .ko artifacts, not by "CC [M]" line count: this
#      tree's Kbuild prints zero "CC [M]" lines even on a build that fully
#      succeeds -- confirmed with V=1 too, verbose mode changes nothing here.
#      A .ko file appearing after `make <target>` is the real success signal
#      on this tree; counting compiler lines would misgrade it FAIL(0) always.
#      PASS requires EVERY subsystem the board declares to produce its .ko,
#      not merely one of them: a per-subsystem `make` that fails prints no
#      "error:" line (a Make-level "No rule to make target" is not a compiler
#      error), so a missing .ko is the only signal a broken subsystem leaves.
#      A cache-tree row's CC-LINES column shows that as produced/expected
#      (e.g. "3/4"), so the table itself says when a row is a partial build --
#      a bare "3" next to a $KERNELS_DIR row's "9" would read as "built less"
#      instead of "one subsystem missing".
#
# /kernels/linux-4.15.18 (below) is a known, committed exception, named in
# EXPECTED_FAIL_KERNELS below: a run that finds it broken here still exits 0.
# The row is NOT hidden -- it still prints, still shows CC-LINES 0, and is
# graded "FAIL (expected)" instead of a plain "FAIL", so a reader sees the
# allowance the run carried instead of silence (the summary block also names
# it, see "expected kernel failure carried" below). That tree stops before
# the compiler ever runs (missing objtool -- see project memo
# kernels-4-15-18-tree-unfinished), which is a broken HOST TREE, not evidence
# about the 4.15 KERNEL LINE; the linux-4.15.0-101 cache-tree row above is
# that evidence. The allowance runs in both directions: if this tree ever
# starts building clean here, the run exits 1 and names it, because an
# expected failure that quietly starts passing means EXPECTED_FAIL_KERNELS
# and README are now wrong and nothing else would notice. EXCLUDE_KERNELS
# still exists, separately, as a per-run acknowledgement rather than a
# committed one; where a tree is named in both, EXCLUDE_KERNELS wins -- it
# is the stronger "do not grade this tree at all".
#
# The exit code also covers a tree that never reaches a row at all. Every
# tree under $KERNELS_DIR and $KERNELS_CACHE_DIR is either a required tree --
# one README's Supported kernels table stakes a row on -- or one of the three
# dev trees nobody's row cites (NUC980, buildroot, intel-lts). A required
# tree that is missing, present but not prepared, or (for the cache tree) has
# no $KERNELS_CACHE_DIR at all fails the run: README made a claim this run
# did not measure. A tree nobody cites keeps landing in Skipped with no
# effect on the exit code, same as always -- its absence proves nothing about
# a claim this project makes. EXCLUDE_KERNELS excuses a required tree's
# absence the same way it already excuses a graded FAIL.
#
# A third source of coverage, orthogonal to the two above: the KERNEL axis
# ($KERNELS_DIR / $KERNELS_CACHE_DIR loops) says nothing about the SOURCE
# axis -- which of the 17 files under src/hal/ a run actually asked the
# compiler to build. BOARDS below picks two boards that between them
# declare all four subsystems, but that only proves every subsystem
# compiles for the one chip family those two boards happen to use; a chip
# family no board in BOARDS selects can carry a silent break -- e.g. a
# wrong _Static_assert chip-id check in a SIO HAL (milestone 9) -- and no
# build in this script would ever reach it to find out. The coverage pass
# below closes that gap: it derives every distinct "shape" (the exact set
# of HAL .c files a board's .conf selects) from configs/boards/*.conf at
# runtime, builds one representative board per shape on $COVERAGE_KERNEL,
# and fails the run if any src/hal/*/*.c file is never reported compiled by
# any build in any pass. An uncompiled HAL file is a failure here, not a
# footnote -- it is a claim this run did not measure, the same standard the
# required-tree audit above already holds the kernel axis to.
#
# record_compiled_hal_files reads a file's "CC [M]" line, which Kbuild prints
# before a compiler error on that same file, so a file that fails to compile
# is still recorded as compiled. On a measured coverage kernel this is moot --
# that row's own ERRORS count already fails the run. Excluding the coverage
# kernel itself via EXCLUDE_KERNELS is the one path where this could let a
# broken file pass unnoticed, but excluding a kernel already means accepting
# that this run knows nothing true about that kernel's breaks (see
# EXCLUDE_KERNELS above) -- the HAL audit built from that same excluded
# kernel's log inherits the same acceptance, not a new gap.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNELS_DIR="${KERNELS_DIR:-/kernels}"
KERNELS_CACHE_DIR="${KERNELS_CACHE_DIR:-/kernels-cache}"
EXCLUDE_KERNELS="${EXCLUDE_KERNELS:-}"

# The HAL source-file coverage pass (see the header comment above): the tree
# it builds one representative board per shape on, and an optional override
# of which boards to build instead of the derived shape representatives.
COVERAGE_KERNEL="${COVERAGE_KERNEL:-linux-5.4.302}"
COVERAGE_BOARDS="${COVERAGE_BOARDS:-}"

# The trees README's "Supported kernels" table stakes a row on. Keep this
# list in sync with that table -- update README.md alongside it. A required
# tree that produces no row fails the run (see the header comment above).
REQUIRED_KERNELS_DIR_TREES=(linux-4.15.18 linux-5.4.302 linux-5.15.211 linux-6.6.89 linux-6.8.2 linux-6.12.27 linux-6.14)
REQUIRED_KERNELS_CACHE_DIR_TREES=(linux-4.15.0-101)

# Trees known not to build on THIS host, committed rather than per-run (see
# the header comment above). linux-4.15.18 stops before the compiler runs
# here -- it is missing objtool (project memo kernels-4-15-18-tree-unfinished)
# -- which is a broken host tree, not evidence about the 4.15 kernel line;
# the linux-4.15.0-101 cache-tree rows are the real 4.15 evidence, and they
# both PASS. Whichever grading site names a tree here -- the $KERNELS_DIR
# loop, the $KERNELS_CACHE_DIR loop, or the HAL coverage pass -- a tree on
# this list that fails is graded "FAIL (expected)" and does not fail the
# run; one that unexpectedly passes does (see below).
EXPECTED_FAIL_KERNELS=(linux-4.15.18)

# Two boards: EPC-WHL declares watchdog + hwmon + gpio; ESM-KX60G declares
# all four subsystems -- together they cover every SUBSYSTEM (the kernel
# axis: modpost, Kbuild wiring, the driver-side glue). They do NOT cover
# every CHIP (the source axis): both use the same ITE/pca9555/i801 HALs, so
# a HAL file only a different chip family reaches -- nct61x6d, f81966,
# nct5655, zhaoxin -- is compiled by neither. The coverage pass below (see
# the header comment) covers that axis instead.
BOARDS=(EPC-WHL ESM-KX60G)

# What each required tree backs in README, named for the failure report below.
declare -A REQUIRED_TREE_NOTE=(
	[linux-4.15.18]="README's 4.15.18 row went unmeasured"
	[linux-5.4.302]="README's 5.4.302 row went unmeasured"
	[linux-5.15.211]="README's 5.15.211 row went unmeasured"
	[linux-6.6.89]="README's 6.6.89 row went unmeasured"
	[linux-6.8.2]="README's 6.8.2 row went unmeasured"
	[linux-6.12.27]="README's 6.12.27 row went unmeasured"
	[linux-6.14]="README's 6.14.0 row went unmeasured"
	[linux-4.15.0-101]="README's two 4.15.0-101 rows (EPC-WHL, ESM-KX60G) went unmeasured"
)

is_excluded() {
	local kernel="$1"
	for ex in $EXCLUDE_KERNELS; do
		[ "$ex" = "$kernel" ] && return 0
	done
	return 1
}

is_expected_fail() {
	local kernel="$1"
	for ef in "${EXPECTED_FAIL_KERNELS[@]}"; do
		[ "$ef" = "$kernel" ] && return 0
	done
	return 1
}

# One function decides a row's STATUS ("PASS" / "FAIL (excluded)" /
# "FAIL (expected)" / "FAIL") and its effect on overall_rc,
# EXPECTED_FAIL_CARRIED and NOW_PASSING_EXPECTED, from a kernel name plus one
# already-computed "did this build succeed" boolean. Every grading site (the
# $KERNELS_DIR loop, the $KERNELS_CACHE_DIR loop, the coverage pass) calls
# this instead of keeping its own copy of the decision, so a fourth grading
# site cannot forget the expected-fail allowance the way the cache loop and
# the coverage pass both did before this. Sets $GRADE_STATUS rather than
# echoing it -- call it plain, never inside "$(...)": a command substitution
# forks a subshell, and overall_rc / the two arrays below would be set only
# in that subshell and lost the instant it returns.
grade_row() {
	local kernel="$1" built_ok="$2"
	if [ "$built_ok" -eq 1 ]; then
		GRADE_STATUS="PASS"
		if is_expected_fail "$kernel" && ! is_excluded "$kernel"; then
			NOW_PASSING_EXPECTED+=("$kernel")
			overall_rc=1
		fi
	elif is_excluded "$kernel"; then
		GRADE_STATUS="FAIL (excluded)"
	elif is_expected_fail "$kernel"; then
		GRADE_STATUS="FAIL (expected)"
		EXPECTED_FAIL_CARRIED+=("$kernel")
	else
		GRADE_STATUS="FAIL"
		overall_rc=1
	fi
}

# The .ko a subsystem target produces (matches the Makefile's own KO_<drv>).
ko_for_target() {
	case "$1" in
	watchdog) echo "wdt.ko" ;;
	gpio) echo "gpio.ko" ;;
	hwmon) echo "hwm.ko" ;;
	misc) echo "misc.ko" ;;
	esac
}

# Which subsystem targets a board's own .conf declares -- read from its
# MAKE_<X>_DEVICE keys, the same keys the top-level Makefile itself gates on.
# Only needed for cache trees, which cannot use a bare `make` (see above).
board_targets() {
	local board="$1" conf="$REPO_ROOT/configs/boards/${board}.conf"
	local targets=()
	grep -q '^MAKE_WDT_DEVICE=' "$conf" && targets+=(watchdog)
	grep -q '^MAKE_GPIO_DEVICE=' "$conf" && targets+=(gpio)
	grep -q '^MAKE_HWM_DEVICE=' "$conf" && targets+=(hwmon)
	grep -q '^MAKE_MISC_DEVICE=' "$conf" && targets+=(misc)
	echo "${targets[@]}"
}

# The HAL .c files a board's .conf selects, one per subsystem where BOTH
# MAKE_<X>_DEVICE and MAKE_<X>_CHIPSET are set (Kbuild's own wiring), plus
# the GPIO protocol object when MAKE_GPIO_PROTOCOL is set. Colon-joined on
# one line, not newline-joined -- a raw newline as an associative-array
# subscript hits bash's "bad array subscript" parsing and silently kills the
# loop that uses it below, so keep this colon-joined form even though a
# newline-joined one would read more naturally.
board_hal_fileset() {
	local board="$1" conf="$REPO_ROOT/configs/boards/${board}.conf"
	local files=()
	local dev chip proto

	dev="$(sed -n 's/^MAKE_WDT_DEVICE=//p' "$conf")"
	chip="$(sed -n 's/^MAKE_WDT_CHIPSET=//p' "$conf")"
	if [ -n "$dev" ] && [ -n "$chip" ]; then
		files+=("src/hal/$dev/$chip.c" "src/hal/$dev/${chip}_wdt.c")
	fi

	dev="$(sed -n 's/^MAKE_GPIO_DEVICE=//p' "$conf")"
	chip="$(sed -n 's/^MAKE_GPIO_CHIPSET=//p' "$conf")"
	if [ -n "$dev" ] && [ -n "$chip" ]; then
		files+=("src/hal/$dev/$chip.c" "src/hal/$dev/${chip}_gpio.c")
		proto="$(sed -n 's/^MAKE_GPIO_PROTOCOL=//p' "$conf")"
		[ -n "$proto" ] && files+=("src/hal/$dev/$proto.c")
	fi

	dev="$(sed -n 's/^MAKE_HWM_DEVICE=//p' "$conf")"
	chip="$(sed -n 's/^MAKE_HWM_CHIPSET=//p' "$conf")"
	if [ -n "$dev" ] && [ -n "$chip" ]; then
		files+=("src/hal/$dev/$chip.c" "src/hal/$dev/${chip}_hwm.c")
	fi

	dev="$(sed -n 's/^MAKE_MISC_DEVICE=//p' "$conf")"
	chip="$(sed -n 's/^MAKE_MISC_CHIPSET=//p' "$conf")"
	if [ -n "$dev" ] && [ -n "$chip" ]; then
		files+=("src/hal/$dev/$chip.c" "src/hal/$dev/${chip}_misc.c")
	fi

	printf '%s\n' "${files[@]}" | sort -u | paste -sd: -
}

# Feed the audit (see the header comment above) from a build's own log --
# called from EVERY build in EVERY pass (the existing $KERNELS_DIR loop, the
# existing $KERNELS_CACHE_DIR loop, and the coverage pass below), right
# before that build's log is deleted, so the audit reflects every build the
# whole run performs. A "CC [M]" line's object path is absolute (e.g.
# "$REPO_ROOT/src/hal/ec/ite.o"); strip through "src/hal/" and swap .o for .c.
declare -A COMPILED_HAL_FILES=()
record_compiled_hal_files() {
	local log="$1" f
	while IFS= read -r f; do
		[ -n "$f" ] && COMPILED_HAL_FILES["$f"]=1
	done < <(grep -oE '/src/hal/[^[:space:]]+\.o' "$log" | sed -E 's#.*/src/hal/#src/hal/#; s/\.o$/.c/')
}

# Shape derivation (see the header comment above), run once before any
# building starts. A board file that is a symlink to another resolves to
# one object before shapes are counted (ADP-226-01.conf -> ADP-226.conf),
# so the coverage pass reports over the 109 distinct board files, not 110
# board paths.
declare -A CANON_SEEN=()
CANON_BOARDS=()
for conf in "$REPO_ROOT"/configs/boards/*.conf; do
	real="$(readlink -f "$conf")"
	[ -n "${CANON_SEEN["$real"]:-}" ] && continue
	CANON_SEEN["$real"]=1
	CANON_BOARDS+=("$(basename "$real" .conf)")
done

declare -A SHAPE_SEEN=() SHAPE_FILESET=() SHAPE_COUNT=() SHAPE_REP=() FILE_OWNER=()
SHAPE_KEYS=()
for board in "${CANON_BOARDS[@]}"; do
	fileset="$(board_hal_fileset "$board")"
	key="k:$fileset" # "k:" prefix: an EMPTY key (a board with no subsystem,
	                 # e.g. ACP-BYT2C) hits the same "bad array subscript"
	                 # bash bug as a newline key and silently kills the loop
	                 # below -- always keep this prefix.
	if [ -z "${SHAPE_SEEN["$key"]+x}" ]; then
		SHAPE_SEEN["$key"]=1
		SHAPE_FILESET["$key"]="$fileset"
		SHAPE_COUNT["$key"]=0
		SHAPE_REP["$key"]="$board"
		SHAPE_KEYS+=("$key")
	fi
	SHAPE_COUNT["$key"]=$((SHAPE_COUNT["$key"] + 1))

	IFS=':' read -ra flist <<<"$fileset"
	for f in "${flist[@]}"; do
		[ -n "$f" ] && [ -z "${FILE_OWNER["$f"]:-}" ] && FILE_OWNER["$f"]="$board"
	done
done

# Representatives to actually build in the coverage pass: the override if
# the caller gave one (testing the instrument itself, or reproducing
# master's blind spot), else one per derived shape.
if [ -n "$COVERAGE_BOARDS" ]; then
	# shellcheck disable=SC2206
	COVERAGE_REPS=($COVERAGE_BOARDS)
	COVERAGE_REP_COUNTS=()
	for _ in "${COVERAGE_REPS[@]}"; do COVERAGE_REP_COUNTS+=("-"); done
else
	COVERAGE_REPS=()
	COVERAGE_REP_COUNTS=()
	for key in "${SHAPE_KEYS[@]}"; do
		COVERAGE_REPS+=("${SHAPE_REP["$key"]}")
		COVERAGE_REP_COUNTS+=("${SHAPE_COUNT["$key"]}")
	done
fi

declare -a ROWS=()
declare -a SKIPPED=()
declare -a EXPECTED_FAIL_CARRIED=()
declare -a NOW_PASSING_EXPECTED=()
overall_rc=0
dirs_seen=0
cache_dirs_seen=0

if [ ! -d "$KERNELS_DIR" ]; then
	echo "build-matrix: kernel directory '$KERNELS_DIR' not found" >&2
	exit 1
fi

shopt -s nullglob
for kernel_dir in "$KERNELS_DIR"/*/; do
	kernel="$(basename "$kernel_dir")"
	dirs_seen=$((dirs_seen + 1))

	# A tree only builds if it was actually prepared (modules_prepare-equivalent
	# has been run); read the directory rather than hard-coding tree names, so
	# a new tree dropped into $KERNELS_DIR is picked up automatically.
	if [ ! -d "${kernel_dir}include/generated" ]; then
		SKIPPED+=("$kernel|no include/generated (tree not prepared)")
		continue
	fi

	for board in "${BOARDS[@]}"; do
		# Clean between combinations -- leftover objects from the previous
		# kernel/board would give a false PASS.
		(cd "$REPO_ROOT" && make clean KERNEL_SOURCE="$kernel_dir" BOARD_NAME="$board") >/dev/null 2>&1

		log="$(mktemp)"
		(cd "$REPO_ROOT" && make BOARD_NAME="$board" KERNEL_SOURCE="$kernel_dir") >"$log" 2>&1

		cc_count=$(grep -c 'CC \[M\]' "$log")
		err_count=$(grep -c 'error:' "$log")
		record_compiled_hal_files "$log"
		rm -f "$log"

		(cd "$REPO_ROOT" && make clean KERNEL_SOURCE="$kernel_dir" BOARD_NAME="$board") >/dev/null 2>&1

		built_ok=0
		[ "$cc_count" -gt 0 ] && [ "$err_count" -eq 0 ] && built_ok=1
		grade_row "$kernel" "$built_ok"
		status="$GRADE_STATUS"

		ROWS+=("$kernel|$board|$cc_count|$err_count|$status")
	done
done

# Cache trees: see the header comment above for why these exist and why
# they are graded differently (per-subsystem builds, .ko-count grading).
if [ -d "$KERNELS_CACHE_DIR" ]; then
	for cache_root in "$KERNELS_CACHE_DIR"/*/; do
		kernel="$(basename "$cache_root")"
		cache_dirs_seen=$((cache_dirs_seen + 1))

		hdr_dirs=("${cache_root}usr/src/linux-headers-"*"-generic/")
		if [ "${#hdr_dirs[@]}" -eq 0 ] || [ ! -d "${hdr_dirs[0]}include/generated" ]; then
			SKIPPED+=("$kernel|no prepared linux-headers-*-generic tree under $cache_root (cache tree not ready)")
			continue
		fi
		kernel_dir="${hdr_dirs[0]}"

		for board in "${BOARDS[@]}"; do
			targets="$(board_targets "$board")"
			# shellcheck disable=SC2206
			target_arr=($targets)
			expected_count="${#target_arr[@]}"
			ko_count=0
			err_count=0

			for target in $targets; do
				(cd "$REPO_ROOT" && make clean KERNEL_SOURCE="$kernel_dir" BOARD_NAME="$board") >/dev/null 2>&1

				log="$(mktemp)"
				(cd "$REPO_ROOT" && make "$target" BOARD_NAME="$board" KERNEL_SOURCE="$kernel_dir") >"$log" 2>&1
				err_count=$((err_count + $(grep -c 'error:' "$log")))
				record_compiled_hal_files "$log"
				rm -f "$log"

				ko="$(ko_for_target "$target")"
				[ -f "$REPO_ROOT/$ko" ] && ko_count=$((ko_count + 1))
			done

			(cd "$REPO_ROOT" && make clean KERNEL_SOURCE="$kernel_dir" BOARD_NAME="$board") >/dev/null 2>&1

			built_ok=0
			[ "$expected_count" -gt 0 ] && [ "$ko_count" -eq "$expected_count" ] && [ "$err_count" -eq 0 ] && built_ok=1
			grade_row "$kernel" "$built_ok"
			status="$GRADE_STATUS"

			ROWS+=("$kernel|$board|$ko_count/$expected_count|$err_count|$status")
		done
	done
else
	SKIPPED+=("linux-4.15 (cache)|no $KERNELS_CACHE_DIR directory found (cache kernel tree not present on this host)")
fi

# HAL source-file coverage pass: one representative board per HAL shape,
# built on $COVERAGE_KERNEL under $KERNELS_DIR (see the header comment
# above for why). Kept in its own COVERAGE_ROWS array, separate from ROWS,
# so the required-tree audit below -- which keys off ROWS by kernel name
# only -- cannot be perturbed by it.
declare -a COVERAGE_ROWS=()
coverage_kernel_dir="$KERNELS_DIR/$COVERAGE_KERNEL/"
if [ ! -d "${coverage_kernel_dir}include/generated" ]; then
	if is_excluded "$COVERAGE_KERNEL"; then
		SKIPPED+=("$COVERAGE_KERNEL (coverage)|no include/generated (tree not prepared) -- HAL source-file coverage pass skipped, excluded")
	else
		echo "build-matrix: coverage kernel '$COVERAGE_KERNEL' not found or not prepared under $KERNELS_DIR -- the HAL source-file coverage pass needs it to compile one board per HAL shape" >&2
		overall_rc=1
	fi
else
	for i in "${!COVERAGE_REPS[@]}"; do
		board="${COVERAGE_REPS[$i]}"
		count="${COVERAGE_REP_COUNTS[$i]}"
		fileset="$(board_hal_fileset "$board")"

		(cd "$REPO_ROOT" && make clean KERNEL_SOURCE="$coverage_kernel_dir" BOARD_NAME="$board") >/dev/null 2>&1

		log="$(mktemp)"
		(cd "$REPO_ROOT" && make BOARD_NAME="$board" KERNEL_SOURCE="$coverage_kernel_dir") >"$log" 2>&1

		cc_count=$(grep -c 'CC \[M\]' "$log")
		err_count=$(grep -c 'error:' "$log")
		record_compiled_hal_files "$log"
		rm -f "$log"

		(cd "$REPO_ROOT" && make clean KERNEL_SOURCE="$coverage_kernel_dir" BOARD_NAME="$board") >/dev/null 2>&1

		# A board whose .conf selects no subsystem (today, only ACP-BYT2C)
		# builds nothing at all -- graded PASS on err_count alone, or it
		# would always read FAIL(0) for having zero "CC [M]" lines.
		if [ -z "$fileset" ]; then
			built_ok=0
			[ "$err_count" -eq 0 ] && built_ok=1
		else
			built_ok=0
			[ "$cc_count" -gt 0 ] && [ "$err_count" -eq 0 ] && built_ok=1
		fi

		grade_row "$COVERAGE_KERNEL" "$built_ok"
		status="$GRADE_STATUS"

		COVERAGE_ROWS+=("$count|$board|$cc_count|$err_count|$status")
	done
fi

if [ "${#ROWS[@]}" -eq 0 ]; then
	echo "build-matrix: no prepared kernel tree found under $KERNELS_DIR -- nothing was built" >&2
	exit 1
fi

# Required-tree audit: the exit code covers exactly the rows README's table
# claims (see the header comment above for the rule).
declare -A row_seen=()
for row in "${ROWS[@]}"; do
	IFS='|' read -r kernel _ <<<"$row"
	row_seen["$kernel"]=1
done

REQUIRED_TOTAL=$((${#REQUIRED_KERNELS_DIR_TREES[@]} + ${#REQUIRED_KERNELS_CACHE_DIR_TREES[@]}))
measured_required=0
declare -a UNMET_REQUIRED=()
for kernel in "${REQUIRED_KERNELS_DIR_TREES[@]}" "${REQUIRED_KERNELS_CACHE_DIR_TREES[@]}"; do
	if [ -n "${row_seen[$kernel]:-}" ]; then
		measured_required=$((measured_required + 1))
	else
		UNMET_REQUIRED+=("$kernel|${REQUIRED_TREE_NOTE[$kernel]}")
		is_excluded "$kernel" || overall_rc=1
	fi
done

# HAL source-file audit: compare what the compiler actually reported (every
# "CC [M]" line recorded by record_compiled_hal_files, across every build in
# every pass above) against the .c files present on disk. A file no build
# ever reached fails the run (see the header comment above).
ALL_HAL_FILES=()
while IFS= read -r f; do ALL_HAL_FILES+=("$f"); done < <(cd "$REPO_ROOT" && printf '%s\n' src/hal/*/*.c | sort)
UNCOMPILED_HAL=()
for f in "${ALL_HAL_FILES[@]}"; do
	[ -z "${COMPILED_HAL_FILES["$f"]:-}" ] && UNCOMPILED_HAL+=("$f")
done
hal_total=${#ALL_HAL_FILES[@]}
hal_compiled=$((hal_total - ${#UNCOMPILED_HAL[@]}))
[ "${#UNCOMPILED_HAL[@]}" -gt 0 ] && overall_rc=1

possible=$(((dirs_seen + cache_dirs_seen) * ${#BOARDS[@]}))
echo "${#ROWS[@]} of $possible combinations built"
echo "$measured_required of $REQUIRED_TOTAL required kernel trees measured"
echo "$hal_compiled of $hal_total HAL source files compiled"
if [ "${#EXPECTED_FAIL_CARRIED[@]}" -gt 0 ]; then
	# A kernel is carried once per board it is graded against (BOARDS has
	# two entries), so de-duplicate down to distinct kernel names before
	# reporting the count -- one board catching it is enough to name it.
	mapfile -t carried_unique < <(printf '%s\n' "${EXPECTED_FAIL_CARRIED[@]}" | sort -u)
	printf -v carried_list '%s, ' "${carried_unique[@]}"
	echo "${#carried_unique[@]} expected kernel failure carried: ${carried_list%, }"
fi
echo
printf '%-18s %-12s %10s %8s %-14s\n' "KERNEL" "BOARD" "CC-LINES" "ERRORS" "STATUS"
for row in "${ROWS[@]}"; do
	IFS='|' read -r kernel board cc err status <<<"$row"
	printf '%-18s %-12s %10s %8s %-14s\n' "$kernel" "$board" "$cc" "$err" "$status"
done

if [ "${#COVERAGE_ROWS[@]}" -gt 0 ]; then
	echo
	echo "HAL source-file coverage pass (one board per HAL shape, on $COVERAGE_KERNEL):"
	printf '%6s %-12s %10s %8s %-14s\n' "COUNT" "BOARD" "CC-LINES" "ERRORS" "STATUS"
	for row in "${COVERAGE_ROWS[@]}"; do
		IFS='|' read -r count board cc err status <<<"$row"
		printf '%6s %-12s %10s %8s %-14s\n' "$count" "$board" "$cc" "$err" "$status"
	done
fi

if [ "$overall_rc" -ne 0 ] && [ "${#UNMET_REQUIRED[@]}" -gt 0 ]; then
	echo
	echo "Unmeasured required trees (README claims this run did not back):"
	for unmet in "${UNMET_REQUIRED[@]}"; do
		IFS='|' read -r kernel note <<<"$unmet"
		echo "  $kernel -- $note"
	done
fi

if [ "${#NOW_PASSING_EXPECTED[@]}" -gt 0 ]; then
	echo
	echo "Expected-fail kernels that now build clean (update EXPECTED_FAIL_KERNELS and README):"
	# Same per-board duplication as EXPECTED_FAIL_CARRIED above -- de-duplicate.
	mapfile -t now_passing_unique < <(printf '%s\n' "${NOW_PASSING_EXPECTED[@]}" | sort -u)
	for kernel in "${now_passing_unique[@]}"; do
		echo "  $kernel -- now builds clean here; remove it from EXPECTED_FAIL_KERNELS and update its README row"
	done
fi

if [ "${#UNCOMPILED_HAL[@]}" -gt 0 ]; then
	echo
	echo "Uncompiled HAL source files (no build in this run reached them):"
	for f in "${UNCOMPILED_HAL[@]}"; do
		owner="${FILE_OWNER[$f]:-}"
		if [ -n "$owner" ]; then
			echo "  $f -- no build compiled it; configs/boards/${owner}.conf selects it"
		else
			echo "  $f -- no board selects it (orphan HAL file)"
		fi
	done
fi

if [ "${#SKIPPED[@]}" -gt 0 ]; then
	echo
	echo "Skipped (no prepared kernel tree):"
	for skip in "${SKIPPED[@]}"; do
		IFS='|' read -r kernel reason <<<"$skip"
		echo "  $kernel -- $reason"
	done
fi

if [ "$overall_rc" -ne 0 ]; then
	echo
	echo "build-matrix: FAILED -- one or more kernels did not build clean, or a"
	echo "required tree or HAL source file went unmeasured (see the report above)."
	echo "Add a kernel name to \$EXCLUDE_KERNELS to acknowledge a known break."
fi

exit "$overall_rc"
