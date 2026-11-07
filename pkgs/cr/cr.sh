# cr: review this repo's changes in tuicr, then hand the review to a running Claude Code session.
#
#   cr               uncommitted changes (opens tuicr's target picker when the tree is clean)
#   cr <base>        this branch's commits since <base>, e.g. `cr main`, `cr origin/main`
#   cr pr <n|url>    a GitHub PR: `:submit` posts the review to GitHub; `y` also sends it to Claude
#   cr to-pr [<n>]   copy this branch's saved local review comments into its GitHub PR review and open it,
#                    so `:submit` can post them (`:submit` only works in PR mode). Lines are re-anchored to
#                    the PR's code; ones it can't find become file comments. $CR_SESSION picks the session.
#   cr -- <args>     any other tuicr arguments, verbatim (`cr -- -r HEAD~3..HEAD -p src/`)
#
# Inside tuicr: `y` (or `:wq` → y) ends the review and sends it, `:q` quits without sending, `e` opens the
# line in your editor (in nvim's <leader>gr float: jumps the surrounding nvim there, <leader>gr comes back).
# Where it goes: $CR_TARGET if set (tmux pane id like %3, or a herdr agent pane id), else the Claude Code
# pane(s) whose cwd is inside this repo (fzf picks when there are several), else any Claude Code pane.
# With no Claude pane at all the review lands in the clipboard instead.

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
review=$(mktemp -t cr.XXXXXX.md)
to_pr_log=""
trap 'rm -f "$review" ${to_pr_log:+"$to_pr_log"}; jobs -p | xargs -r kill 2>/dev/null || true' EXIT

# ---- cr to-pr ---------------------------------------------------------------------------------------------
# tuicr creates a PR's review session only once it opens the PR, so: pick the local session now, open the PR,
# and copy the comments in from the background as soon as that session is live (tuicr shows them within ~1s).

# Line where `want_rev:path` lines start..end now sit in `have_rev:path` (nearest exact match), or nothing.
# want_rev WORKTREE means the file on disk.
relocate() {
  local want_rev=$1 have_rev=$2 path=$3 start=$4 end=$5 want have
  if [ "$want_rev" = WORKTREE ]; then
    want=$(sed -n "${start},${end}p" "$root/$path" 2>/dev/null) || return 1
  else
    want=$(git -C "$root" show "$want_rev:$path" 2>/dev/null | sed -n "${start},${end}p") || return 1
  fi
  have=$(git -C "$root" show "$have_rev:$path" 2>/dev/null) || return 1
  [ -n "$want" ] || return 1
  printf '%s\n' "$have" | WANT="$want" awk -v n=$((end - start + 1)) -v orig="$start" '
    { line[NR] = $0 }
    END {
      best = ""; for (i = 1; i + n - 1 <= NR; i++) {
        block = line[i]; for (j = 1; j < n; j++) block = block "\n" line[i + j]
        if (block == ENVIRON["WANT"]) { d = i - orig; if (d < 0) d = -d; if (best == "" || d < bestd) { best = i; bestd = d } }
      }
      if (best != "") print best
    }'
}

copy_to_pr_session() {
  local source=$1 pr_slug=$2 pr_head=$3 base_ref=$4 local_new=$5 comments existing
  local local_base pr_base copied=0 moved=0 filed=0 skipped=0 failed=0
  for _ in $(seq 1 120); do # the PR can take a while to fetch on first open
    tuicr review list --repo "$root" 2>/dev/null | jq -e --arg s "$pr_slug" 'any(.[]; .slug == $s and .active)' >/dev/null && break
    sleep 0.5
  done
  comments=$(tuicr review comments --session "$source" --repo "$root")
  existing=$(tuicr review comments --session "$pr_slug" 2>/dev/null || echo '[]')
  local_base=$(git -C "$root" merge-base "origin/$base_ref" HEAD 2>/dev/null || echo "")
  pr_base=$(git -C "$root" merge-base "origin/$base_ref" "$pr_head" 2>/dev/null || echo "")

  while IFS= read -r c; do
    local path start end side type content line note="" payload
    path=$(jq -r '.path // ""' <<<"$c"); start=$(jq -r '.start_line // ""' <<<"$c"); end=$(jq -r '.end_line // .start_line // ""' <<<"$c")
    side=$(jq -r '.side // "new"' <<<"$c"); type=$(jq -r '.comment_type // ""' <<<"$c"); content=$(jq -r '.content' <<<"$c")
    # Rerunning `cr to-pr` must not duplicate what an earlier run copied:
    if jq -e --arg p "$path" --arg b "$content" 'any(.[]; (.path // "") == $p and (.content | endswith($b)))' <<<"$existing" >/dev/null; then
      skipped=$((skipped + 1)); continue
    fi
    if [ -n "$path" ] && [ -n "$start" ]; then
      if [ "$side" = old ]; then line=$(relocate "${local_base:-HEAD}" "${pr_base:-$pr_head}" "$path" "$start" "$end" || true)
      else line=$(relocate "$local_new" "$pr_head" "$path" "$start" "$end" || true); fi
      if [ -z "$line" ]; then
        local lines=$start
        if [ "$end" != "$start" ]; then lines="$start-$end"; fi
        note="(line $lines in the local review; not found in the PR's version) "
        start=""; filed=$((filed + 1))
      elif [ "$line" != "$start" ]; then
        end=$((end + line - start)); start=$line; moved=$((moved + 1))
      fi
    fi
    payload=$(jq -n --arg content "$note$content" --arg type "$type" --arg file "$path" --arg start "$start" \
      --arg end "$end" --arg side "$side" '{content: $content, side: $side}
        + (if $type != "" and $type != "none" then {comment_type: $type} else {} end)
        + (if $file != "" then {file: $file} else {} end)
        + (if $start != "" then {start_line: ($start | tonumber), end_line: ($end | tonumber)} else {} end)')
    if tuicr review add --session "$pr_slug" --input - <<<"$payload" >/dev/null 2>>"$to_pr_log.err"; then
      copied=$((copied + 1))
    else
      failed=$((failed + 1))
    fi
  done < <(jq -c '.[]' <<<"$comments")

  printf 'cr: copied %s comment(s) from %s into %s (%s re-anchored, %s turned into file comments, %s already there)\n' \
    "$copied" "$source" "$pr_slug" "$moved" "$filed" "$skipped" >"$to_pr_log"
  if [ "$failed" -gt 0 ]; then
    printf 'cr: %s comment(s) could not be added: %s\n' "$failed" "$(tr '\n' ' ' <"$to_pr_log.err")" >>"$to_pr_log"
  fi
  rm -f "$to_pr_log.err"
}

to_pr() {
  local pr=${1:-} info repo pr_head base_ref source local_new sessions
  info=$(gh pr view ${pr:+"$pr"} --json number,headRefOid,baseRefName 2>/dev/null) ||
    { echo "cr: no GitHub PR for this branch (pass its number: cr to-pr <n>)" >&2; exit 1; }
  pr=$(jq -r .number <<<"$info"); pr_head=$(jq -r .headRefOid <<<"$info"); base_ref=$(jq -r .baseRefName <<<"$info")
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  git -C "$root" fetch -q origin "refs/pull/$pr/head" "$base_ref" 2>/dev/null || true

  if [ -n "${CR_SESSION:-}" ]; then
    source=$CR_SESSION
  else
    sessions=$(tuicr review list --repo "$root" | jq -r '.[] | select(.kind == "local" and .comment_count > 0)
      | [.slug, (.comment_count | tostring) + " comments", (if .active then "open" else "" end)] | @tsv')
    [ -n "$sessions" ] || { echo "cr: no saved local review comments here (\`:w\` in tuicr saves them)" >&2; exit 1; }
    if [ "$(wc -l <<<"$sessions")" -eq 1 ]; then source=$(cut -f1 <<<"$sessions")
    else source=$(fzf --delimiter='\t' --prompt="copy which review into PR #$pr > " --height=40% --reverse <<<"$sessions" | cut -f1); fi
    [ -n "$source" ] || exit 1
  fi
  # New-side lines of a commit-range review are HEAD's; worktree/staged reviews are the files on disk.
  case "$source" in */commits/*) local_new=$(git -C "$root" rev-parse HEAD) ;; *) local_new=WORKTREE ;; esac

  to_pr_log=$(mktemp -t cr-to-pr.XXXXXX.log)
  copy_to_pr_session "$source" "gh:$repo/pr/$pr" "$pr_head" "$base_ref" "$local_new" </dev/null >/dev/null 2>&1 &
  args=(pr "$pr")
}

case "${1:-}" in
  "")
    if [ -n "$(git -C "$root" status --porcelain 2>/dev/null)" ]; then args=(-w); else args=(); fi ;;
  --) shift; args=("$@") ;;
  -h | --help) sed -n '/^# cr:/,/^$/s/^# \{0,1\}//p' "$0"; exit 0 ;;
  to-pr) shift; to_pr "$@" ;;
  pr | mr | tui | -*) args=("$@") ;;
  *) args=(-r "$1..HEAD") ;;
esac

# Inside nvim's terminal, tuicr's `e` should jump the parent nvim to the line (pkgs/cr/nvim-shim.sh):
if [ -n "${NVIM:-}" ]; then PATH="@nvimShim@:$PATH"; fi

# --stdout renders the TUI on /dev/tty and prints the export on exit, so stdout stays clean for us:
tuicr --stdout "${args[@]}" >"$review"
if [ -n "$to_pr_log" ]; then
  # Let a copy that is mid-flight finish; one still waiting for the PR to open has nothing left to do.
  for _ in $(seq 1 15); do [ -s "$to_pr_log" ] || [ -z "$(jobs -rp)" ] && break; sleep 0.2; done
  if [ -s "$to_pr_log" ]; then cat "$to_pr_log" >&2; else echo "cr: the PR review closed before its comments were copied in" >&2; fi
fi
[ -s "$review" ] || exit 0

# Candidates as "kind<TAB>id<TAB>cwd<TAB>label", kind = tmux | herdr.
candidates() {
  if tmux info >/dev/null 2>&1; then
    tmux list-panes -a -F $'tmux\t#{pane_id}\t#{pane_current_path}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_current_command}' |
      awk -F'\t' -v OFS='\t' '$5 == "claude" { print $1, $2, $3, $4 }'
  fi
  if command -v herdr >/dev/null 2>&1; then
    herdr agent list 2>/dev/null |
      jq -r '.. | .agents? // empty | .[] | select((.agent // "") | test("claude"; "i"))
        | ["herdr", .pane_id, (.foreground_cwd // .cwd // "-"), ((.name // .pane_id) + " [" + .agent_status + "]")] | @tsv' 2>/dev/null || true
  fi
}

pick() {
  local all here
  all=$(candidates)
  [ -n "$all" ] || return 1
  here=$(awk -F'\t' -v r="$root" '$3 == r || index($3, r "/") == 1' <<<"$all")
  [ -n "$here" ] || here=$all
  if [ "$(wc -l <<<"$here")" -eq 1 ]; then
    printf '%s\n' "$here"
  else
    fzf --delimiter='\t' --with-nth=4,3 --prompt='send review to claude > ' --height=40% --reverse <<<"$here"
  fi
}

if [ -n "${CR_TARGET:-}" ]; then
  case "$CR_TARGET" in %*) target=$(printf 'tmux\t%s\t-\t%s' "$CR_TARGET" "$CR_TARGET") ;; *) target=$(printf 'herdr\t%s\t-\t%s' "$CR_TARGET" "$CR_TARGET") ;; esac
else
  target=$(pick) || target=""
  if [ -z "$target" ] && [ -n "$(candidates)" ]; then
    printf 'cr: nothing picked, review not sent (rerun with CR_TARGET=%%N to pick a pane).\n' >&2
    cat "$review"
    exit 1
  fi
fi

comments=$(grep -cE '^[0-9]+\. ' "$review" || true)
[ "$comments" = 1 ] && comments="1 comment" || comments="$comments comments"

if [ -z "$target" ]; then
  wl-copy <"$review" 2>/dev/null || tmux load-buffer - <"$review" 2>/dev/null || true
  printf 'cr: no Claude Code pane found; review (%s) copied to the clipboard.\n' "$comments" >&2
  exit 0
fi

IFS=$'\t' read -r kind id cwd label <<<"$target"
case "$kind" in
  tmux)
    # Bracketed paste (-p) so Claude Code takes the multi-line review as one pasted block, then submit.
    # A busy Claude queues it and picks it up after the current turn.
    tmux load-buffer -b cr - <"$review"
    tmux paste-buffer -p -d -b cr -t "$id"
    sleep 0.3
    tmux send-keys -t "$id" Enter
    ;;
  herdr)
    # Rejected (agent_blocked) while Claude waits on a permission/question dialog: answer it, then rerun.
    herdr agent prompt "$id" "$(cat "$review")" >/dev/null
    ;;
esac

printf 'cr: sent review (%s) to Claude Code @ %s %s\n' "$comments" "$label" "${cwd/#"$HOME"/\~}" >&2
