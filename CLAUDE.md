# Avalue-driver — agent guide

Linux kernel driver suite for Avalue SBC / embedded boards. **Everything is
driven by a per-board config file** `configs/boards/<BOARD_NAME>.conf`; the build
turns it into `src/configs/board.h` and compiles per-subsystem modules. Nothing
board-specific is hard-coded in the `.c` files.

## Build

- `make help` documents everything. On the target board `BOARD_NAME`
  auto-detects from DMI — pass `BOARD_NAME=<x>` only to cross-build off-target.
- `make` (all enabled subsystems) · `make gpio|hwmon|watchdog|misc` (one) ·
  `make <sub>-debug` (CONFIG_DEBUG=y) · `sudo make install` · `make clean`.
- A board only builds the subsystems its `.conf` declares in full (both
  `MAKE_*_DEVICE` and `MAKE_*_CHIPSET`); asking for one it lacks, or one whose
  chipset key is empty, stops with a clear error, not `src/hal//.o`.
- Kbuild uses `-Wall -Wextra -Werror`: builds must be warning-clean.

## Architecture (HAL)

- `src/drivers/` — the four kernel modules (watchdog, gpio, hwmon, misc).
- `src/hal/<device>/<chipset>[_<subsystem>].c` — pluggable HALs selected by the
  `.conf`'s `MAKE_*_DEVICE` / `MAKE_*_CHIPSET` (+ `MAKE_GPIO_PROTOCOL` for SMBus).
  Chips: `ec/ite`, `sio/f81966`, `sio/nct61x6d`, `smb/nct5655`, `smb/pca9555`;
  SMBus host protocol `i801` or `zhaoxin` (both implement the neutral `smb_*`
  interface in `smb.h`, one linked per board).
- Adding a board or chip: `configs/README.md` is the extraction guide (HAL matrix,
  value-formatting rules, verification steps).

## Repo conventions (must follow)

- **Ported `.conf` → `NOT HARDWARE-VALIDATED` banner** until someone bench-tests
  and removes it. Tag unconfirmed values `# TODO verify`. Keeping shortly describe 
	comment in .conf, there is no need to handover the history, write the current
	status as well.
- **`config.sh` value shapes**: a `CONFIG_*_REG` must be a `MACRO(x)` (with
  parens) or a raw literal (`0x39`) — a bare `UPPER_CASE` token gets wrapped in
  quotes and breaks the header. Labels must be quoted; never put a trailing inline
  comment on a value line.
- **A `#if`-guarded `CONFIG_*` key needs a fallback, or boards that omit it stop
  building.** The kernel compiles with `-Wundef` and `Kbuild` adds `-Werror`, so a
  key a board's `.conf` never declares is a hard error inside `#if`, not a silent
  `0`. Board files routinely omit keys they do not use -- 93 of the 110 never
  mention `CONFIG_HWM_FAN_2_ENABLE`. So adding a guarded channel to a driver is a
  **two-file change**: the driver, and an `#ifndef <key>` / `#define <key> 0`
  fallback beside its group in `src/configs/config.h`. That fallback is only safe
  when it means the feature is off. A key that names real hardware — a register
  address, an I/O port, a slave address, a pin mask — gets no fallback anywhere:
  a wrong one still compiles, loads, and touches hardware nobody declared, so it
  comes from the board file instead, and `scripts/config.sh` stops the build with
  the board file and the missing key before any compiler runs (this is how the
  GPIO register keys in `src/hal/ec/ite.h` and the SMBus base port and slave
  addresses in `src/hal/smb/smb.h` are checked). A board names the chip it
  carries once, in `CONFIG_CHIPID`. `f81966` and `nct61x6d` refuse a chip that
  is not the one named; the ITE probe only warns and keeps loading on a
  mismatch, because most boards' `CONFIG_CHIPID` is still an unverified guess
  (`# TODO verify` in the `.conf`) and refusing on a guess would stop a
  shipping board's driver from loading. A group's whole `_NUM` / `_MAP` keys
  are the opposite case: they are **mandatory**, not defaulted, for any
  subsystem the board really builds (both its `MAKE_*_DEVICE` and
  `MAKE_*_CHIPSET` set) -- the right count is the
  HAL's own slot count, not a board fact, so `config.h` cannot fall back to one.
  `scripts/config.sh` checks this and stops with the board file and the missing
  key before any compiler runs. So `config.h` carries no `#ifndef` fallback for a
  group's `_NUM` / `_MAP` key — such a fallback could not even compile (`_NUM 0`
  paired with `_MAP { 0 }` is a zero-element array initializer), and would only
  hide the message `config.sh` already gives.
- **Hardware truth beats legacy and guesses.** The EC BRAM maps at
  `/mnt/datacore/sw-source/Beta_BIOS/<board>/EC/*_EC_BRAM_map.{txt,md}` are
  authoritative for register layout. The 3.x source being ported is at
  `/home/workspace/Avalue_driver_deprecate` (per-board `<board>_init()` in
  `config/config.c`; chip HALs in `core/`).
- EC register layout **varies per board** (GPIO bank, fan tach register — ITE has
  a 5-ADC family with fan at 0x35 and an 8-ADC family with fan at 0x39). Take it
  from the BRAM map; do not assume. Registers that differ are conf-driven, not
  hard-coded in the HAL.

## GitLab collaboration — the orchestra contract

This repo follows the **gitlab-review contract** in the craft mount at
`/home/workspace/claude-autopilot/craft/gitlab-review/` — `README.md` for the
shared conventions, `orchestra.md` for how the roles compose into one autopilot.

The three execution roles **never overlap**: the side that writes code is never
the side that reviews it, and neither is the side that admits it to `master`. A
round here plays them as an **orchestra** — it drives the whole loop for one work
item and dispatches short-lived sub-agents rather than doing the work itself:

- **musician** (`coding` sub-agent) — takes one packaged task, writes the change
  on a branch, pushes it. It never reviews and never admits.
- **concertmaster** (`review` sub-agent) — grades that branch's diff against the
  craft specs and returns PASS or CHANGES-NEEDED. It never authors what it reviews.
- **conductor** — admit, tag, close. The round plays the **closing half** of this
  seat: it may settle a genuinely resolved issue itself (`autopilot close`,
  `autopilot resolve`) after posting a signed note that names the commit or the
  reason. It never plays the **admitting** half — `autopilot mr-merge` is denied to
  it at the tool layer, so the round opens the MR and stops, and the human clicks
  Merge. That last lock is a permission rather than a promise.

Commission a sub-agent with one complete, self-contained package — the task, the
repo context, the exact gate command — per `gitlab-review/agent-handoff.md`; the
receiver should never have to guess.

- **One task → one branch off `master` → change → build green locally → push →
  open exactly ONE MR (target `master`) → stop.** The human reviews and merges.
- **Proceed autonomously; ask only for the unknowable** — a wire byte, a flash
  address, a register you cannot derive. Ask in the MR/issue thread instead of
  inventing; a guessed value is worse than a question.
- **MR description is self-contained**: the finding, before→after, behaviour
  change, and how it was verified.
- **Every reference is a clickable link**, and a code line is a SHA-pinned blob
  URL (`http://192.168.100.17/internal/avalue-driver-4.0/-/blob/<40-sha>/<path>#L<n>`).
  Full syntax: `gitlab-review/gitlab-citations.md`.
- **The toolkit signs for you.** `autopilot mr-create` / `issue-note` / `reply`
  append the round's signature from its own identity, so write only your own
  prose — a hand-typed signature on top double-signs.
- **The board is label-free**: whose turn it is rides on **who spoke last**, told
  apart by that signature, not on a `status::` label. The one exception is
  `status::blocked-decision`, which belongs to the human — never add or remove it,
  and never build on an issue that carries it.
- Remote is self-hosted GitLab (`http://192.168.100.17/internal/avalue-driver-4.0`).
  Reach it through the `autopilot` verbs (`issue-list`, `mr-list`, `show`,
  `mr-create`, …): raw `glab` is denied here at the tool layer.
- Reply **in-thread** and `@`-mention the other party (that is what feeds their
  todo inbox); keep chat to a status line — all repo business lives on GitLab.

## Working style

- Work each task in its own checkout — a `git worktree` or a fresh clone branched
  off `origin/master`, created **outside** this tree. This checkout is bind-mounted
  into running containers, and a worktree or a stray `index.lock` on its live
  `.git` is the documented way to jam the fleet. After the merge lands, remove the
  worktree + local branch and `git fetch --prune`.
- Conversational replies in Chinese; all docs / markdown / code comments in
  English.
