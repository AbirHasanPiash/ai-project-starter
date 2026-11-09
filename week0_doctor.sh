#!/usr/bin/env bash
# week0_doctor.sh: checks every week-0 item on this Mac. It only reads; it changes nothing.
#
#   ./week0_doctor.sh            check the Mac and the tools
#   ./week0_doctor.sh --repos    also check the project repos in ~/code (or $CODE_DIR)
#
# Exit code 0 means no failures (warnings are allowed).

set -u
code_dir="${CODE_DIR:-$HOME/code}"
pass=0 warn=0 fail=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass + 1)); }
meh()  { printf '  \033[33m!\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      tip: %s\n' "$2"; warn=$((warn + 1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      fix: %s\n' "$2"; fail=$((fail + 1)); }
info() { printf '  \033[36mi\033[0m %s\n' "$1"; }
has()  { command -v "$1" >/dev/null 2>&1; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

head_ "Mac"
if [ "$(uname -m)" = "arm64" ]; then ok "Apple silicon (arm64)"; else bad "This Mac is $(uname -m), not arm64" "The guide assumes an Apple-silicon Mac."; fi
ok "macOS $(sw_vers -productVersion), $(( $(sysctl -n hw.memsize) / 1073741824 )) GB memory"
free_gb=$(df -g /System/Volumes/Data | awk 'NR == 2 { print $4 }')
if [ "$free_gb" -ge 50 ]; then ok "Free disk: ${free_gb} GB"
elif [ "$free_gb" -ge 30 ]; then meh "Free disk: ${free_gb} GB (aim for 50 GB or more)" "Guide, step 1.2"
else bad "Free disk: only ${free_gb} GB" "Free space before installing anything: guide, step 1.2"; fi
if xcode-select -p >/dev/null 2>&1; then ok "Command Line Tools: $(xcode-select -p)"; else bad "Command Line Tools missing" "xcode-select --install"; fi

head_ "Core tools"
if has brew; then ok "Homebrew $(brew --version 2>/dev/null | head -1 | awk '{ print $2 }')"
else bad "Homebrew missing" "Guide, step 1.3"; fi
if has git; then ok "git $(git --version | awk '{ print $3 }')"; else bad "git missing" "brew install git"; fi
name=$(git config --global user.name 2>/dev/null || true)
email=$(git config --global user.email 2>/dev/null || true)
if [ -n "$name" ]; then ok "git user.name: $name"; else bad "git user.name not set" 'git config --global user.name "Your Name"'; fi
if [ -n "$email" ]; then ok "git user.email: $email"; else bad "git user.email not set" 'git config --global user.email "you@example.com"'; fi
if has gh; then
  if gh auth status >/dev/null 2>&1; then ok "GitHub CLI logged in as $(gh api user --jq .login 2>/dev/null)"
  else bad "GitHub CLI not logged in" "gh auth login"; fi
else bad "GitHub CLI missing" "brew install gh"; fi
vscode=$(mdfind 'kMDItemCFBundleIdentifier == "com.microsoft.VSCode"' 2>/dev/null | head -1)
case "$vscode" in
  /Applications/*) ok "VS Code in /Applications" ;;
  "") meh "VS Code not found" "Install it, or skip this if you use another editor" ;;
  *) meh "VS Code is at $vscode" "Move it to /Applications: guide, step 1.4" ;;
esac
if has code; then ok "'code' command available"
else meh "'code' command not in PATH" "In VS Code: Cmd+Shift+P, then 'Shell Command: Install code command in PATH'"; fi

head_ "Python toolchain"
if has uv; then
  ok "uv $(uv --version | awk '{ print $2 }')"
  if uv python find 3.14 >/dev/null 2>&1; then ok "Python 3.14 available to uv"
  else bad "Python 3.14 not installed for uv" "uv python install 3.14"; fi
else bad "uv missing" "brew install uv"; fi
if has pre-commit; then ok "pre-commit $(pre-commit --version | awk '{ print $2 }')"
else bad "pre-commit missing" "uv tool install pre-commit --with pre-commit-uv"; fi
info "ruff and pytest live inside each project (uv add --dev); --repos checks them"

head_ "Docker"
if has docker; then
  if docker info >/dev/null 2>&1; then
    ok "Docker engine running (server $(docker version --format '{{.Server.Version}}' 2>/dev/null))"
    arch=$(docker info --format '{{.Architecture}}' 2>/dev/null)
    if [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then ok "Docker runs native arm64 Linux ($arch)"; else meh "Docker architecture: $arch"; fi
  else bad "Docker engine not running" "open -a Docker, then wait until the whale icon stops animating"; fi
  if docker compose version >/dev/null 2>&1; then ok "$(docker compose version | head -1)"
  else bad "docker compose missing" "Update Docker Desktop: guide, step 3.2"; fi
else bad "docker missing" "Install Docker Desktop: guide, step 3.2"; fi

if [ "${1:-}" = "--repos" ]; then
  head_ "Project repos in $code_dir"
  found=0
  for d in "$code_dir"/*/; do
    [ -d "$d/.git" ] || continue
    found=$((found + 1))
    repo=$(basename "$d")
    if url=$(git -C "$d" remote get-url origin 2>/dev/null); then ok "$repo: remote $url"
    else meh "$repo: no GitHub remote yet" "gh repo create $repo --public --source $d --push"; fi
    tracked=$(git -C "$d" ls-files | grep -E '(^|/)\.env(\..+)?$' | grep -v '\.env\.example$' || true)
    if [ -n "$tracked" ]; then bad "$repo: secret file tracked by git: $tracked" "git rm --cached <file>, commit, then rotate every key in it"
    else ok "$repo: no .env file tracked by git"; fi
    if [ -f "$d/.git/hooks/pre-commit" ]; then ok "$repo: pre-commit hook installed"
    else meh "$repo: pre-commit hook not installed" "cd $d && pre-commit install"; fi
    if [ -f "$d/uv.lock" ]; then ok "$repo: uv.lock present"; else meh "$repo: no uv.lock" "cd $d && uv lock"; fi
    if [ -x "$d/.venv/bin/ruff" ] && [ -x "$d/.venv/bin/pytest" ]; then ok "$repo: ruff and pytest installed in .venv"
    else meh "$repo: ruff or pytest missing from .venv" "cd $d && make setup"; fi
  done
  [ "$found" -gt 0 ] || meh "No git repos found in $code_dir" "Guide, part 6"
fi

printf '\n%d passed, %d warnings, %d failed\n' "$pass" "$warn" "$fail"
[ "$fail" -eq 0 ]
