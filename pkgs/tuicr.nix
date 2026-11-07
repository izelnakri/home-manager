# tuicr: GitHub-style PR review TUI for agent-written diffs (Rust, ratatui). Config: static/.config/tuicr/
# nixpkgs-unstable ships 0.26.0 (26.05 doesn't have it at all). 0.27/0.28 bring regex diff search, the
# `:theme` picker, `--line`, editor stdio re-attach under `--stdout` (needed by `cr`), PR merge-base
# diffs & carrying a review forward when a PR gets new commits, so bump it here.
# Delete this file & use `unstable.tuicr` directly once nixpkgs-unstable reaches >= 0.28.0.
# To bump: change `version`, set both hashes (src, cargoDeps) to lib.fakeHash, build, and paste the hashes nix reports.
{ lib, unstable, fetchFromGitHub }:

unstable.tuicr.overrideAttrs (finalAttrs: prev: {
  version = "0.28.0";

  src = fetchFromGitHub {
    owner = "agavra";
    repo = "tuicr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Q1VcRGTN3BO/UYTY0/SBN05v/0Dy+iEUNFshHoBjNVM=";
  };

  # NOTE: overrideAttrs can't just set `cargoHash`: buildRustPackage already turned it into `cargoDeps`.
  cargoDeps = unstable.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-+HbzMHq3OCuF+RCGXaLSbN4+xcFTYyKUI54advFKcEU=";
  };

  # Local UX patches (rebase them on a version bump if they stop applying; drop once upstream has them):
  patches = (prev.patches or [ ]) ++ [
    # The diff-search `[n/total]` counter sat after the hint text and was hidden while any status message
    # was up (incl. search's own "search hit BOTTOM, continuing at TOP"), so it often vanished.
    ./tuicr-search-count-always-visible.patch
    # In the file tree, g/G moved the diff (first file / last line) instead of the tree selection; now they
    # select the first/last row like vim's gg/G, as j/k already move the selection. `{N}G` is unchanged.
    ./tuicr-file-tree-g-shift-g.patch
    # tuicr can copy lines (visual `y`) and comments (`Y`) but not a file's path, a hunk or a file's diff:
    # <leader>p / :name (like nvim's :Name), <leader>y / :yank hunk, <leader>Y / :yank file (as a patch).
    ./tuicr-copy-path-hunk-file.patch
    # Visual `y` copies one side's code, so removed lines are lost; visual `Y` copies the selection as diff
    # text (both sides, +/- markers) under a `path:lines` header, ready to paste to an agent.
    ./tuicr-yank-selection-as-diff.patch
  ];
})
