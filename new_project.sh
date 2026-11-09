#!/usr/bin/env bash
# new_project.sh: create one project from the week-0 starter, locally and on GitHub.
#
#   ./new_project.sh <repo-name> "<title>" "<one-line goal>" "<start>" [--local-only]
#
#   ./new_project.sh tiny-gpt-bangla "Tiny GPT from scratch" \
#       "A character-level GPT, a BPE tokenizer and a KV cache in PyTorch." "Nov 2026"
#
# The steps, each explained in Part 6 of week_0_setup_guide.html:
#   1. uv init --package            pyproject.toml, src/<package>/, .python-version, git repo
#   2. copy template/               CI, pre-commit, Makefile, README, LICENSE, tests, evals, scripts
#   3. append pyproject_tools.toml  ruff and pytest settings
#   4. uv add --dev ruff pytest     dev tools, pinned in uv.lock
#   5. format, lint, test           the skeleton is green before the first commit
#   6. pre-commit install, commit   the hooks run on this very first commit
#   7. gh repo create --public      skipped with --local-only
#
# Settings you can override: CODE_DIR (default ~/code), PYTHON_VERSION (default 3.14).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template="$here/template"
code_dir="${CODE_DIR:-$HOME/code}"
python_version="${PYTHON_VERSION:-3.14}"

die()  { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1m▸ %s\033[0m\n' "$*"; }

[ $# -ge 4 ] || die "Usage: $0 <repo-name> \"<title>\" \"<one-line goal>\" \"<start>\" [--local-only]"
repo="$1" title="$2" goal="$3" start="$4" mode="${5:-}"
[ -z "$mode" ] || [ "$mode" = "--local-only" ] || die "Unknown option: $mode"

case "$repo" in
  "" | -* | *- | *--* | *[!a-z0-9-]*) die "Repo name must be lowercase letters, digits and single dashes: '$repo'" ;;
esac
pkg="${repo//-/_}"
dir="$code_dir/$repo"

# ---------------------------------------------------------------- preflight
for cmd in git uv pre-commit perl rsync; do
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found. Finish Part 2 of the guide first."
done
[ -d "$template" ] || die "Template folder not found: $template"
[ ! -e "$dir" ] || die "$dir already exists. Delete or rename it, or pick another name."
author="$(git config --global user.name || true)"
[ -n "$author" ] || die "Set your name first: git config --global user.name \"Your Name\""

if [ "$mode" = "--local-only" ]; then
  user="${GITHUB_USER:-$(gh api user --jq .login 2>/dev/null || echo your-github-username)}"
else
  command -v gh >/dev/null 2>&1 || die "'gh' not found. Run: brew install gh"
  gh auth status >/dev/null 2>&1 || die "GitHub CLI is not logged in. Run: gh auth login"
  user="$(gh api user --jq .login)"
  if gh repo view "$user/$repo" >/dev/null 2>&1; then die "github.com/$user/$repo already exists."; fi
fi

# ------------------------------------------------------------------ 1. init
step "1/7  uv init --package $repo (Python $python_version) in $dir"
mkdir -p "$code_dir"
uv init --package --name "$repo" --python "$python_version" "$dir"
cd "$dir"

# -------------------------------------------------------------- 2. template
step "2/7  Copy the template (overwrites uv's README.md and .gitignore)"
rsync -a "$template/" "$dir/"
export T_TITLE="$title" T_GOAL="$goal" T_START="$start" T_REPO="$repo" \
       T_USER="$user" T_PKG="$pkg" T_YEAR="$(date +%Y)" T_AUTHOR="$author"
perl -pi -e '
  s/__TITLE__/$ENV{T_TITLE}/g;  s/__GOAL__/$ENV{T_GOAL}/g;  s/__START__/$ENV{T_START}/g;
  s/__REPO__/$ENV{T_REPO}/g;    s/__USER__/$ENV{T_USER}/g;  s/__PKG__/$ENV{T_PKG}/g;
  s/__YEAR__/$ENV{T_YEAR}/g;    s/__AUTHOR__/$ENV{T_AUTHOR}/g;
' README.md LICENSE tests/test_smoke.py

# ------------------------------------------------------------- 3. settings
step "3/7  Description, ruff and pytest settings in pyproject.toml"
perl -pi -e 'BEGIN { ($g = $ENV{T_GOAL}) =~ s/(["\\])/\\$1/g } s/^description = .*$/description = "$g"/' pyproject.toml
printf '\n' >> pyproject.toml
cat "$here/pyproject_tools.toml" >> pyproject.toml

# ------------------------------------------------------------- 4. dev tools
step "4/7  uv add --dev ruff pytest"
uv add --dev ruff pytest

# ------------------------------------------------------------ 5. all green
step "5/7  Format, lint, test"
uv run ruff format .
uv run ruff check --fix .
uv run ruff format --check .
uv run pytest -m "not eval"

# ---------------------------------------------------------- 6. first commit
step "6/7  Install git hooks, run them once, commit"
pre-commit install
git add -A
if ! pre-commit run --all-files; then
  echo "Hooks changed some files (normal on the first run). Running them again."
  git add -A
  pre-commit run --all-files
fi
git add -A
git commit -q -m "Project skeleton: uv, ruff, pytest, pre-commit, CI"
git log --oneline -1

# ---------------------------------------------------------------- 7. GitHub
if [ "$mode" = "--local-only" ]; then
  step "7/7  Skipped GitHub (--local-only). Project ready at $dir"
  exit 0
fi
step "7/7  Create github.com/$user/$repo (public) and push"
gh repo create "$repo" --public --source . --remote origin --push --description "$goal"
printf '\n\033[32m✓ https://github.com/%s/%s\033[0m\n' "$user" "$repo"
