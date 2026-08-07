#!/bin/bash
# Drives the REAL docs/push.sh against scratch git repos it builds itself,
# proving the guards issue #66 asked for: every refusal path (bad WIKI_DIR,
# missing token, an unreviewed source repo, an out-of-sync wiki clone), that
# nothing publishes on decline or --dry-run, that a real publish touches
# only the owned page(s) and names the source commit, that the token never
# reaches disk or output, that docs/wiki/ cannot drift out of OWNED_PAGES /
# NOT_PUBLISHED_PAGES in silence (Fix A), and that the freshness message
# tells "behind" / "ahead" / "truly diverged" apart instead of calling all
# three "diverged" (Fix B). See test/README.md.
#
# This never touches the real wiki, the real /workspace/Avalue-wiki clone
# (if present), docs/wiki/ in this checkout, or the network -- every source
# repo and every wiki repo used here is a fresh local git repo under a
# mktemp -d scratch directory removed when the run ends.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUSH_SH="$REPO_ROOT/docs/push.sh"

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

checked=0
failures=0
ok() { echo "[PUSH-CHECK]: OK: $1"; checked=$((checked+1)); }
fail() { echo "[PUSH-CHECK]: FAILED: $1"; checked=$((checked+1)); failures=$((failures+1)); }

# ---------------------------------------------------------------------
# Fixture builders, reused by every case below.
# ---------------------------------------------------------------------

# Builds a scratch bare repo + working clone that stands in for THIS repo.
# Copies the real docs/push.sh into it (so the harness always exercises the
# actual script under test) plus two wiki pages matching OWNED_PAGES /
# NOT_PUBLISHED_PAGES, commits, pushes, so HEAD == origin/master. Prints the
# clone's path.
setup_source_repo() {
    local src_bare="$SCRATCH/source-origin-$$-$RANDOM.git"
    local src_clone="$SCRATCH/source-clone-$$-$RANDOM"
    git init --bare -q "$src_bare"
    git clone -q "$src_bare" "$src_clone" 2>/dev/null
    git -C "$src_clone" config user.email "push-check@example.invalid"
    git -C "$src_clone" config user.name "push-check"
    mkdir -p "$src_clone/docs/wiki"
    cp "$PUSH_SH" "$src_clone/docs/push.sh"
    chmod +x "$src_clone/docs/push.sh"
    printf '# Linux X86 API\n\nfixture.\n' > "$src_clone/docs/wiki/Linux-X86-API.md"
    printf '# Supported Boards\n\nfixture.\n' > "$src_clone/docs/wiki/Supported-Boards.md"
    git -C "$src_clone" add -A
    git -C "$src_clone" commit -q -m "scratch source fixture"
    git -C "$src_clone" branch -M master
    git -C "$src_clone" push -q origin master
    echo "$src_clone"
}

# Builds a scratch bare "wiki" repo (name must end in .wiki.git -- that's
# the only thing docs/push.sh checks) + a working clone, with one
# pre-existing page unrelated to what any test publishes, so a case that
# must leave the wiki alone has something to prove untouched. Prints the
# clone's path; the bare repo's own path can always be recovered from the
# clone with `git -C <clone> remote get-url origin`.
setup_wiki_repo() {
    local tag="$1"   # short unique tag, e.g. "happy", "behind", "ahead"
    local wiki_bare="$SCRATCH/${tag}-$$-$RANDOM.wiki.git"
    local wiki_clone="$SCRATCH/${tag}-$$-$RANDOM-clone"
    git init --bare -q "$wiki_bare"
    git clone -q "$wiki_bare" "$wiki_clone" 2>/dev/null
    git -C "$wiki_clone" config user.email "push-check@example.invalid"
    git -C "$wiki_clone" config user.name "push-check"
    printf '# Home\n\nfixture, unrelated to any owned page.\n' > "$wiki_clone/Home.md"
    git -C "$wiki_clone" add -A
    git -C "$wiki_clone" commit -q -m "scratch wiki fixture"
    git -C "$wiki_clone" branch -M master
    git -C "$wiki_clone" push -q origin master
    echo "$wiki_clone"
}

# Wiki clone A is left strictly BEHIND its own origin: a second clone B of
# the same bare repo pushes one more commit that A never fetched. Prints
# A's path (the one to hand to docs/push.sh).
setup_behind_wiki_fixture() {
    local tag="$1"
    local wiki_clone_a wiki_bare wiki_clone_b
    wiki_clone_a=$(setup_wiki_repo "${tag}-a")
    wiki_bare=$(git -C "$wiki_clone_a" remote get-url origin)
    wiki_clone_b="$SCRATCH/${tag}-b-$$-$RANDOM-clone"
    git clone -q "$wiki_bare" "$wiki_clone_b" 2>/dev/null
    git -C "$wiki_clone_b" config user.email "push-check@example.invalid"
    git -C "$wiki_clone_b" config user.name "push-check"
    echo "extra line from clone B" >> "$wiki_clone_b/Home.md"
    git -C "$wiki_clone_b" commit -q -am "extra commit via clone B, pushed"
    git -C "$wiki_clone_b" push -q origin master
    echo "$wiki_clone_a"
}

# The wiki clone handed to docs/push.sh is left strictly AHEAD of its own
# origin: one commit made locally, never pushed -- exactly the state a
# failed push (docs/push.sh:248) leaves behind. Prints its path.
setup_ahead_wiki_fixture() {
    local tag="$1"
    local wiki_clone
    wiki_clone=$(setup_wiki_repo "$tag")
    echo "local only edit, never pushed" >> "$wiki_clone/Home.md"
    git -C "$wiki_clone" commit -q -am "local only commit, not pushed"
    echo "$wiki_clone"
}

# Wiki clone A is left truly diverged from its own origin: a commit made
# locally in A that is never pushed, AND a different commit pushed via a
# second clone B of the same bare repo. Prints A's path.
setup_diverged_wiki_fixture() {
    local tag="$1"
    local wiki_clone_a wiki_bare wiki_clone_b
    wiki_clone_a=$(setup_wiki_repo "${tag}-a")
    wiki_bare=$(git -C "$wiki_clone_a" remote get-url origin)
    echo "local only edit on A, never pushed" >> "$wiki_clone_a/Home.md"
    git -C "$wiki_clone_a" commit -q -am "A: local only commit, not pushed"

    wiki_clone_b="$SCRATCH/${tag}-b-$$-$RANDOM-clone"
    git clone -q "$wiki_bare" "$wiki_clone_b" 2>/dev/null
    git -C "$wiki_clone_b" config user.email "push-check@example.invalid"
    git -C "$wiki_clone_b" config user.name "push-check"
    echo "different edit on B, pushed" >> "$wiki_clone_b/Home.md"
    git -C "$wiki_clone_b" commit -q -am "B: pushed commit"
    git -C "$wiki_clone_b" push -q origin master
    echo "$wiki_clone_a"
}

# A wiki clone that sits NESTED inside a source clone's own directory --
# the real layout issue #67 measured (/workspace/Avalue-wiki inside the
# driver checkout /workspace), left untracked in the source clone's git.
# Builds a normal bare+clone pair via setup_wiki_repo, then clones that
# same bare repo again (same pattern as setup_diverged_wiki_fixture's
# "clone B") straight into "$src_clone/Avalue-wiki". Prints the nested
# clone's path.
setup_nested_wiki_fixture() {
    local tag="$1" src_clone="$2"
    local wiki_clone_scratch wiki_bare wiki_nested
    wiki_clone_scratch=$(setup_wiki_repo "$tag")
    wiki_bare=$(git -C "$wiki_clone_scratch" remote get-url origin)
    wiki_nested="$src_clone/Avalue-wiki"
    git clone -q "$wiki_bare" "$wiki_nested" 2>/dev/null
    git -C "$wiki_nested" config user.email "push-check@example.invalid"
    git -C "$wiki_nested" config user.name "push-check"
    echo "$wiki_nested"
}

# ---------------------------------------------------------------------
# Runner: drives the SOURCE CLONE's own copy of docs/push.sh (never
# $PUSH_SH directly), feeding it the confirmation word via stdin.
#
#   CONFIRM_INPUT   -- text piped to the "type 'publish'" prompt (default "no")
#   RUN_TOKEN       -- value exported as WIKI_GITHUB_TOKEN (default a fixture value)
#   RUN_UNSET_TOKEN -- when "1", WIKI_GITHUB_TOKEN is left unset for the call
#
# Leaves the combined stdout+stderr in $RUN_OUT and the exit code in $RUN_RC.
# ---------------------------------------------------------------------
run_push() {
    local src_clone="$1" wiki_dir="$2"
    shift 2
    local input="${CONFIRM_INPUT:-no}"
    if [ "${RUN_UNSET_TOKEN:-0}" = "1" ]; then
        RUN_OUT=$(unset WIKI_GITHUB_TOKEN; bash "$src_clone/docs/push.sh" "$wiki_dir" "$@" <<<"$input" 2>&1)
        RUN_RC=$?
    else
        RUN_OUT=$(WIKI_GITHUB_TOKEN="${RUN_TOKEN:-push-check-fixture-token}" bash "$src_clone/docs/push.sh" "$wiki_dir" "$@" <<<"$input" 2>&1)
        RUN_RC=$?
    fi
}

# ---------------------------------------------------------------------
# Box 2 -- one case per refusal path: exit code AND the message names the
# real reason.
# ---------------------------------------------------------------------

box2_not_a_directory() {
    local src_clone missing_dir
    src_clone=$(setup_source_repo)
    missing_dir="$SCRATCH/does-not-exist-$RANDOM-$RANDOM"
    run_push "$src_clone" "$missing_dir"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "is not a directory"; then
        ok "box2: a WIKI_DIR that is not a directory is refused ('is not a directory')."
    else
        fail "box2: WIKI_DIR-not-a-directory case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_not_git_repo() {
    local src_clone plain_dir
    src_clone=$(setup_source_repo)
    plain_dir="$SCRATCH/plain-dir-$$-$RANDOM"
    mkdir -p "$plain_dir"
    run_push "$src_clone" "$plain_dir"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "is not a git repository"; then
        ok "box2: a WIKI_DIR that is a plain directory (no git repo) is refused ('is not a git repository')."
    else
        fail "box2: WIKI_DIR-not-a-git-repo case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_no_origin_remote() {
    local src_clone repo_dir
    src_clone=$(setup_source_repo)
    repo_dir="$SCRATCH/no-origin-$$-$RANDOM"
    git init -q "$repo_dir"
    run_push "$src_clone" "$repo_dir"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "has no 'origin' remote"; then
        ok "box2: a git repo with no 'origin' remote is refused (\"has no 'origin' remote\")."
    else
        fail "box2: no-origin-remote case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_origin_not_wiki() {
    local src_clone wiki_clone origin_url stripped
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_wiki_repo "notwiki")
    origin_url=$(git -C "$wiki_clone" remote get-url origin)
    stripped="${origin_url%.wiki.git}.git"
    git -C "$wiki_clone" remote set-url origin "$stripped"
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "does not look like a wiki clone"; then
        ok "box2: an origin remote not ending in .wiki.git is refused ('does not look like a wiki clone')."
    else
        fail "box2: origin-not-wiki case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_token_unset() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_wiki_repo "notoken")
    RUN_UNSET_TOKEN=1 run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "WIKI_GITHUB_TOKEN is not set"; then
        ok "box2: an unset WIKI_GITHUB_TOKEN is refused ('WIKI_GITHUB_TOKEN is not set'), with otherwise-valid fixtures."
    else
        fail "box2: token-unset case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_source_not_master() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    git -C "$src_clone" checkout -q -b other-branch
    wiki_clone=$(setup_wiki_repo "notmaster")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "not 'master'"; then
        ok "box2: a source repo not on master is refused (\"not 'master'\")."
    else
        fail "box2: source-not-master case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_source_dirty() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    echo "uncommitted edit" >> "$src_clone/docs/wiki/Linux-X86-API.md"
    wiki_clone=$(setup_wiki_repo "dirty")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "dirty working tree"; then
        ok "box2: a dirty source working tree is refused ('dirty working tree')."
    else
        fail "box2: source-dirty case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_source_head_not_synced() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    echo "local only edit" >> "$src_clone/docs/wiki/Linux-X86-API.md"
    git -C "$src_clone" commit -q -am "local only commit, not pushed"
    wiki_clone=$(setup_wiki_repo "headmismatch")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "does not match origin/master"; then
        ok "box2: a source HEAD not pushed to origin/master is refused ('does not match origin/master')."
    else
        fail "box2: source-head-not-synced case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

box2_wiki_out_of_sync() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_behind_wiki_fixture "box2sync")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qiE "behind|ahead|diverged"; then
        ok "box2: an out-of-sync wiki clone is refused (one of the freshness messages)."
    else
        fail "box2: out-of-sync wiki clone case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

# ---------------------------------------------------------------------
# Box 3 -- nothing is published on decline or --dry-run.
# ---------------------------------------------------------------------

box3_decline_and_dry_run() {
    local src_clone wiki_clone before_sha before_files after_sha after_files status_out

    # Decline the prompt.
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_wiki_repo "decline")
    before_sha=$(git -C "$wiki_clone" rev-parse HEAD)
    before_files=$(find "$wiki_clone" -type f -not -path '*/.git/*' | sort)
    CONFIRM_INPUT="no" run_push "$src_clone" "$wiki_clone"
    after_sha=$(git -C "$wiki_clone" rev-parse HEAD)
    after_files=$(find "$wiki_clone" -type f -not -path '*/.git/*' | sort)
    status_out=$(git -C "$wiki_clone" status --porcelain)
    if [ "$RUN_RC" -eq 0 ] && [ "$before_sha" = "$after_sha" ] && [ "$before_files" = "$after_files" ] && [ -z "$status_out" ]; then
        ok "box3: declining the 'publish' prompt leaves the wiki clone byte-for-byte untouched."
    else
        fail "box3: decline case changed the wiki clone -- rc=$RUN_RC before_sha=$before_sha after_sha=$after_sha status='$status_out'"
    fi

    # --dry-run, with the prompt accepted.
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_wiki_repo "dryrun")
    before_sha=$(git -C "$wiki_clone" rev-parse HEAD)
    before_files=$(find "$wiki_clone" -type f -not -path '*/.git/*' | sort)
    CONFIRM_INPUT="publish" run_push "$src_clone" "$wiki_clone" --dry-run
    after_sha=$(git -C "$wiki_clone" rev-parse HEAD)
    after_files=$(find "$wiki_clone" -type f -not -path '*/.git/*' | sort)
    status_out=$(git -C "$wiki_clone" status --porcelain)
    if [ "$RUN_RC" -eq 0 ] && [ "$before_sha" = "$after_sha" ] && [ "$before_files" = "$after_files" ] && [ -z "$status_out" ]; then
        ok "box3: --dry-run leaves the wiki clone byte-for-byte untouched, even after confirming 'publish'."
    else
        fail "box3: --dry-run case changed the wiki clone -- rc=$RUN_RC before_sha=$before_sha after_sha=$after_sha status='$status_out'"
    fi
}

# ---------------------------------------------------------------------
# Box 4 -- a real publish lands the owned page(s) and nothing else.
#
# OWNED_PAGES lists only Linux-X86-API.md (Supported-Boards.md is
# NOT_PUBLISHED_PAGES -- see docs/push.sh and this task's "do not add
# Supported-Boards.md to OWNED_PAGES" rule), so a real run must publish
# Linux-X86-API.md and leave Supported-Boards.md (and Home.md) alone.
# ---------------------------------------------------------------------

box4_real_publish() {
    local src_clone wiki_clone wiki_bare before_head home_before all_ok
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_wiki_repo "publish")
    wiki_bare=$(git -C "$wiki_clone" remote get-url origin)
    home_before=$(cat "$wiki_clone/Home.md")
    before_head=$(git -C "$src_clone" rev-parse HEAD)

    CONFIRM_INPUT="publish" run_push "$src_clone" "$wiki_clone"

    if [ "$RUN_RC" -ne 0 ]; then
        fail "box4: a real publish of a clean, in-sync fixture exited non-zero (rc=$RUN_RC): $RUN_OUT"
        return
    fi

    all_ok=1
    if [ ! -f "$wiki_clone/Linux-X86-API.md" ] || ! cmp -s "$wiki_clone/Linux-X86-API.md" "$src_clone/docs/wiki/Linux-X86-API.md"; then
        fail "box4: Linux-X86-API.md is missing or not byte-identical to the source clone's copy after publish."
        all_ok=0
    fi
    if [ -e "$wiki_clone/Supported-Boards.md" ]; then
        fail "box4: Supported-Boards.md (NOT_PUBLISHED_PAGES, not owned) appeared in the wiki clone -- only owned pages may be published."
        all_ok=0
    fi
    if [ "$(cat "$wiki_clone/Home.md")" != "$home_before" ]; then
        fail "box4: Home.md (not an owned page) changed after publish."
        all_ok=0
    fi
    local commit_msg
    commit_msg=$(git -C "$wiki_clone" log -1 --format=%B)
    if ! printf '%s' "$commit_msg" | grep -qF "$before_head"; then
        fail "box4: the new wiki commit message does not name the source clone's pre-run HEAD ($before_head): $commit_msg"
        all_ok=0
    fi
    local wiki_head_local wiki_head_bare
    wiki_head_local=$(git -C "$wiki_clone" rev-parse HEAD)
    wiki_head_bare=$(git --git-dir="$wiki_bare" rev-parse master 2>/dev/null)
    if [ "$wiki_head_local" != "$wiki_head_bare" ]; then
        fail "box4: the push did not land on the bare wiki repo -- local HEAD=$wiki_head_local, bare master=$wiki_head_bare"
        all_ok=0
    fi
    if [ "$all_ok" -eq 1 ]; then
        ok "box4: a real publish lands Linux-X86-API.md (byte-identical, naming the source SHA), leaves Supported-Boards.md and Home.md untouched, and the push reaches the bare wiki repo."
    fi
}

# ---------------------------------------------------------------------
# Box 5 -- the token never reaches disk or output.
# ---------------------------------------------------------------------

box5_token_not_leaked() {
    local src_clone wiki_clone marker log all_ok
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_wiki_repo "tokenleak")
    marker="PUSHCHECK-TOKEN-MARKER-$RANDOM-$RANDOM"
    log="$SCRATCH/box5-run-$$-$RANDOM.log"

    CONFIRM_INPUT="publish" RUN_TOKEN="$marker" run_push "$src_clone" "$wiki_clone"
    printf '%s\n' "$RUN_OUT" > "$log"

    if [ "$RUN_RC" -ne 0 ]; then
        fail "box5: the publish used to check for a token leak exited non-zero (rc=$RUN_RC): $RUN_OUT"
        return
    fi

    all_ok=1
    if grep -qF -- "$marker" "$log"; then
        fail "box5: the token marker leaked into the script's own stdout/stderr."
        all_ok=0
    fi
    if git -C "$wiki_clone" show --format=%B | grep -qF -- "$marker"; then
        fail "box5: the token marker leaked into the wiki commit's message or diff."
        all_ok=0
    fi
    if grep -rF -q -- "$marker" "$wiki_clone" --exclude-dir=.git 2>/dev/null; then
        fail "box5: the token marker leaked into a file left in the wiki clone."
        all_ok=0
    fi
    if [ "$all_ok" -eq 1 ]; then
        ok "box5: the token never reaches the script's own output, the wiki commit, or any file left in the wiki clone."
    fi
}

# ---------------------------------------------------------------------
# Box 6 (proves Fix A) -- a docs/wiki/ file in neither OWNED_PAGES nor
# NOT_PUBLISHED_PAGES is a refused ownership drift, not a silent gap.
# ---------------------------------------------------------------------

box6_rogue_page_detected() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    printf '# Rogue\n\nnot owned, not excluded -- an ownership drift.\n' > "$src_clone/docs/wiki/Rogue-Page.md"
    git -C "$src_clone" add -A
    git -C "$src_clone" commit -q -m "add a rogue wiki page fixture"
    git -C "$src_clone" push -q origin master
    wiki_clone=$(setup_wiki_repo "rogue")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] \
        && printf '%s' "$RUN_OUT" | grep -qF "Rogue-Page.md" \
        && printf '%s' "$RUN_OUT" | grep -qF "OWNED_PAGES" \
        && printf '%s' "$RUN_OUT" | grep -qF "NOT_PUBLISHED_PAGES"; then
        ok "box6 (Fix A): a docs/wiki/ file in neither list is refused, naming Rogue-Page.md and both arrays."
    else
        fail "box6 (Fix A): a docs/wiki/ file in neither OWNED_PAGES nor NOT_PUBLISHED_PAGES was not refused as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

# ---------------------------------------------------------------------
# Box 8 (proves Fix B) -- behind / ahead / truly-diverged get three
# distinct messages, not all lumped under "diverged".
# ---------------------------------------------------------------------

box8_freshness_three_states() {
    local src_clone wiki_clone

    # behind: origin has commits the local clone never fetched.
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_behind_wiki_fixture "box8behind")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] \
        && printf '%s' "$RUN_OUT" | grep -qi "behind" \
        && printf '%s' "$RUN_OUT" | grep -qi "git pull" \
        && ! printf '%s' "$RUN_OUT" | grep -qi "diverged"; then
        ok "box8 (Fix B): a wiki clone strictly BEHIND origin is refused with 'behind'/'git pull', not 'diverged'."
    else
        fail "box8 (Fix B): behind case did not match the expected message -- rc=$RUN_RC out: $RUN_OUT"
    fi
    # This is the literal old bug (issue #66, measured on !81 issue #64
    # note 11839): a clone genuinely BEHIND origin used to be called
    # "diverged" too. Measure it directly, as its own named check.
    if printf '%s' "$RUN_OUT" | grep -qi "diverged"; then
        fail "box8 old-bug check: a wiki clone strictly BEHIND origin is still labeled 'diverged' -- this is the exact bug issue #66 measured."
    else
        ok "box8 old-bug check: a wiki clone strictly BEHIND origin is no longer mislabeled 'diverged'."
    fi

    # ahead: the local clone committed but never pushed (a failed-push state).
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_ahead_wiki_fixture "box8ahead")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] \
        && printf '%s' "$RUN_OUT" | grep -qi "ahead" \
        && printf '%s' "$RUN_OUT" | grep -qi "retry the push" \
        && ! printf '%s' "$RUN_OUT" | grep -qi "diverged" \
        && ! printf '%s' "$RUN_OUT" | grep -qi "git pull"; then
        ok "box8 (Fix B): a wiki clone strictly AHEAD of origin is refused with 'ahead'/'retry the push', not 'diverged' or 'git pull'."
    else
        fail "box8 (Fix B): ahead case did not match the expected message -- rc=$RUN_RC out: $RUN_OUT"
    fi

    # truly diverged: ahead AND behind at the same time.
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_diverged_wiki_fixture "box8diverged")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] \
        && printf '%s' "$RUN_OUT" | grep -qi "diverged" \
        && printf '%s' "$RUN_OUT" | grep -qi "resolve this by hand" \
        && printf '%s' "$RUN_OUT" | grep -qE '[1-9][0-9]* commit\(s\) ahead' \
        && printf '%s' "$RUN_OUT" | grep -qE '[1-9][0-9]* commit\(s\) behind'; then
        ok "box8 (Fix B): a wiki clone both AHEAD and BEHIND origin is refused as truly 'diverged', naming both counts."
    else
        fail "box8 (Fix B): truly-diverged case did not match the expected message -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

# ---------------------------------------------------------------------
# Issue #67 -- the dirty-tree check must ignore only the wiki clone it
# was pointed at, dynamically (Fix 1), and the ownership check must walk
# docs/wiki/ at any depth, refusing anything that is not a top-level *.md
# page (Fix 2).
# ---------------------------------------------------------------------

issue67_wiki_clone_nested_in_source() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_nested_wiki_fixture "issue67nested" "$src_clone")
    run_push "$src_clone" "$wiki_clone"
    if printf '%s' "$RUN_OUT" | grep -qF "dirty working tree"; then
        fail "issue67: a wiki clone nested inside the source clone (untracked there) still triggered 'dirty working tree' -- rc=$RUN_RC out: $RUN_OUT"
    elif printf '%s' "$RUN_OUT" | grep -qF "Nothing to publish" || printf '%s' "$RUN_OUT" | grep -qF "Type 'publish' to continue"; then
        ok "issue67: a wiki clone nested inside the source clone's own directory does not trip the dirty-tree check -- reaches the normal publish flow."
    else
        fail "issue67: nested-wiki case did not reach the normal publish flow as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

issue67_dirty_elsewhere_with_nested_wiki_still_caught() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_nested_wiki_fixture "issue67dirty" "$src_clone")
    echo "uncommitted edit" >> "$src_clone/docs/wiki/Linux-X86-API.md"
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "dirty working tree"; then
        ok "issue67: a real uncommitted edit elsewhere in the source clone is still refused ('dirty working tree'), even with a nested wiki clone also present."
    else
        fail "issue67: dirty-elsewhere-with-nested-wiki case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

issue67_untracked_elsewhere_with_nested_wiki_still_caught() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    wiki_clone=$(setup_nested_wiki_fixture "issue67untracked" "$src_clone")
    touch "$src_clone/stray-untracked-file.txt"
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] && printf '%s' "$RUN_OUT" | grep -qF "dirty working tree"; then
        ok "issue67: a new untracked file elsewhere in the source clone (not the wiki dir) is still refused ('dirty working tree'), even with a nested wiki clone also present."
    else
        fail "issue67: untracked-elsewhere-with-nested-wiki case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

issue67_nested_file_refused() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    mkdir -p "$src_clone/docs/wiki/images"
    printf 'not really a png, just a fixture\n' > "$src_clone/docs/wiki/images/diagram.png"
    git -C "$src_clone" add -A
    git -C "$src_clone" commit -q -m "add a nested wiki file fixture"
    git -C "$src_clone" push -q origin master
    wiki_clone=$(setup_wiki_repo "issue67nestedfile")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] \
        && printf '%s' "$RUN_OUT" | grep -qF "docs/wiki/images/diagram.png" \
        && printf '%s' "$RUN_OUT" | grep -qF "is not a top-level Markdown page"; then
        ok "issue67: a file inside a subdirectory of docs/wiki/ is refused, naming docs/wiki/images/diagram.png."
    else
        fail "issue67: nested-file case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

issue67_nonmd_toplevel_file_refused() {
    local src_clone wiki_clone
    src_clone=$(setup_source_repo)
    printf 'plain text, not a wiki page\n' > "$src_clone/docs/wiki/notes.txt"
    git -C "$src_clone" add -A
    git -C "$src_clone" commit -q -m "add a non-md top-level wiki file fixture"
    git -C "$src_clone" push -q origin master
    wiki_clone=$(setup_wiki_repo "issue67nonmd")
    run_push "$src_clone" "$wiki_clone"
    if [ "$RUN_RC" -ne 0 ] \
        && printf '%s' "$RUN_OUT" | grep -qF "docs/wiki/notes.txt" \
        && printf '%s' "$RUN_OUT" | grep -qF "is not a top-level Markdown page"; then
        ok "issue67: a top-level non-.md file under docs/wiki/ is refused, naming docs/wiki/notes.txt."
    else
        fail "issue67: non-md-toplevel case did not refuse as expected -- rc=$RUN_RC out: $RUN_OUT"
    fi
}

# ---------------------------------------------------------------------
# Run every box.
# ---------------------------------------------------------------------

box2_not_a_directory
box2_not_git_repo
box2_no_origin_remote
box2_origin_not_wiki
box2_token_unset
box2_source_not_master
box2_source_dirty
box2_source_head_not_synced
box2_wiki_out_of_sync

box3_decline_and_dry_run
box4_real_publish
box5_token_not_leaked
box6_rogue_page_detected
box8_freshness_three_states

issue67_wiki_clone_nested_in_source
issue67_dirty_elsewhere_with_nested_wiki_still_caught
issue67_untracked_elsewhere_with_nested_wiki_still_caught
issue67_nested_file_refused
issue67_nonmd_toplevel_file_refused

if [ "$failures" -gt 0 ]; then
    echo "[PUSH-CHECK]: FAILED: $failures of $checked check(s) failed."
    exit 1
fi

echo "[PUSH-CHECK]: PASS: all $checked check(s) confirmed docs/push.sh's guards, including Fix A (ownership drift) and Fix B (behind/ahead/diverged) from issue #66, and issue #67's nested-wiki-clone dirty-tree exclusion plus the recursive top-level-Markdown-only ownership check."
exit 0
