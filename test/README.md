# Test infrastructure

## Building a real kernel 4.15 tree

`/kernels/linux-4.15.18` on this build host is an incomplete dev tree: a
plain `make` against it stops before the compiler runs, and the tree is also
missing `scripts/mod/modpost` and `tools/objtool/objtool`. That is our host
tree being incomplete, not a fact about the 4.15 kernel line -- see
`README.md`'s Supported Kernels section for what a complete 4.15 tree
actually measures.

`test/build-matrix.sh` carries this tree's break as a committed exception in
`EXPECTED_FAIL_KERNELS`, so a run does not fail because of it: the row still
prints, graded `FAIL (expected)`, and the run exits 0. The same list is
honoured by every grading site the script has -- the `$KERNELS_DIR` loop,
the `$KERNELS_CACHE_DIR` loop, and the HAL source-file coverage pass -- not
only the `/kernels/linux-4.15.18` case this page describes. `EXCLUDE_KERNELS`
is a different, per-run acknowledgement (set by the caller, not committed)
that excuses a tree's failure or absence for one run only; where a tree is
named in both, `EXCLUDE_KERNELS` wins.

To get a complete 4.15 tree, fetch Ubuntu 18.04's own kernel packages
(still served from `archive.ubuntu.com`):

- `linux-headers-4.15.0-101_4.15.0-101.102_all.deb`
- `linux-headers-4.15.0-101-generic_4.15.0-101.102_amd64.deb`

Extract both into the same directory with `dpkg-deb -x <pkg> <dir>` (no
install needed -- both unpack under `usr/src/`). The result carries real
`objtool`, `modpost`, `include/generated`, and its own `Module.symvers` --
none of the dev trees under `/kernels` have that last file.

`test/build-matrix.sh` picks up a tree prepared this way automatically.
Place it under `$KERNELS_CACHE_DIR` (default `/kernels-cache`), laid out as
`<name>/usr/src/linux-headers-*-generic/` -- the exact directory name
(`<name>`) does not matter, and the exact suffix on `linux-headers-*-generic`
(e.g. `-101`) is globbed, not hard-coded. See the script's own header comment
for why this is a second, separate source of trees from `$KERNELS_DIR`, and
how a tree found there is graded differently.

A `/kernels-cache` tree that is missing or not prepared now fails
`test/build-matrix.sh` instead of being skipped quietly -- see the script's
own header comment for the required-tree list this applies to.

A bare `make` (every subsystem the board declares, in one run) fails on 4.15
for a reason in that kernel's own build system (a `KBUILD_MODNAME` conflict
in a file the subsystems share) -- on this kernel line, build one subsystem
at a time instead (`make watchdog`, `make gpio`, `make hwmon`, `make misc`).

## HAL source-file coverage pass

Beyond the kernel matrix above, `test/build-matrix.sh` runs a second pass
that builds one representative board per distinct HAL "shape" -- the exact
set of `src/hal/` files a board's `.conf` selects -- so every HAL `.c` file
any board can reach is compiled at least once, not just the ones the two
kernel-matrix boards happen to use. `COVERAGE_KERNEL` (default
`linux-5.4.302`) names the tree under `$KERNELS_DIR` this pass builds on.
`COVERAGE_BOARDS` overrides the derived shape representatives with an
explicit, space-separated board list -- useful for testing the pass itself,
or for reproducing a narrower run's blind spot on purpose. A HAL source file
that no build in the whole run (this pass or the kernel matrix above)
compiles fails the run; see the script's own header comment for the full
rule.

## Board file sweep (scripts/config.sh over every board)

`test/config-sweep.sh` runs `scripts/config.sh`'s own guard -- the
presence-and-count check on each subsystem's `_NUM`/`_MAP` key pair -- over
every board file, not just the ones something else happens to build.
`scripts/config.sh` already stops a real build before the compiler runs when
a board declares a subsystem (its `MAKE_*_DEVICE`/`MAKE_*_CHIPSET` pair) but
leaves a `_NUM` or `_MAP` key unset, or sets a `_NUM` that disagrees with its
own `_MAP`'s element count -- both would otherwise surface 200 lines into the
compiler as "excess elements in array initializer". The sweep just widens
who gets that check: `test/build-matrix.sh` builds a handful of representative
board files, one per kernel and one per HAL shape; the sweep reads every
board file under `configs/boards/` and hands each to `scripts/config.sh` in
turn, so a board nobody's build happens to reach still gets graded before it
ships to a customer.

A `_MAP` value that does not parse as a `{ ... }` list -- a typo, a missing
brace, any shape this counter has not been taught -- is named by board and
key and counted as **not gradable** in the sweep's own summary line, rather
than being silently skipped or treated as a hard failure.

It compiles nothing and needs no kernel tree. Each board's generated header
goes into a `mktemp -d` scratch directory removed when the run ends, so the
committed tree -- including `src/configs/board.h` -- is never touched;
`scripts/config.sh` alone decides pass or fail. A run prints how many board
names it read, how many distinct files those names resolve to (a symlinked
board file counts once), and how many `_NUM`/`_MAP` pairs it actually
compared -- exit 0 with every board clean, or exit 1 naming every board that
failed.
