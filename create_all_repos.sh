#!/usr/bin/env bash
# create_all_repos.sh: create the seven project repos (P0–P6) with new_project.sh.
#
#   ./create_all_repos.sh               local folders in ~/code + public GitHub repos
#   ./create_all_repos.sh --local-only  local folders only, nothing on GitHub
#
# It lists what it will create and asks before doing anything. If one project
# fails, fix the cause, delete that project's folder, and run again: projects
# that already exist locally are skipped.
#
# P7 (open-source PRs) needs no repo: list your PRs in your profile README.
# P8 (client capstone) gets a repo once there's a client, since it may need to be private.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
code_dir="${CODE_DIR:-$HOME/code}"
mode="${1:-}"
[ -z "$mode" ] || [ "$mode" = "--local-only" ] || { echo "Unknown option: $mode" >&2; exit 1; }

# repo | title | one-line goal (also the GitHub description) | start
projects=(
  "tiny-gpt-bangla|Tiny GPT from scratch|A character-level GPT, a BPE tokenizer and a KV cache in PyTorch, plus measured Bangla vs English token costs across three tokenizers.|Nov 2026"
  "evidence-rag|Evidence-grade RAG|RAG over news and SEC filings with a labelled eval set, an ablation table, a calibrated LLM judge and a CI gate that blocks regressions.|Nov 2026"
  "doc-extract-review|Document extraction with human review|Receipts and invoices to validated JSON, with field-level accuracy, confidence routing, a review UI and cost per document.|Jan 2027"
  "orders-mcp-agent|MCP tools and a reliable agent|A TypeScript MCP server for orders and refunds, and an agent measured by pass^k, cost per task and how safely it fails.|Feb 2027"
  "llm-gateway|LLM gateway on Kubernetes|An OpenAI-compatible gateway with routing, fallbacks, caching and rate limits, load-tested on Kubernetes against SLOs.|Apr 2027"
  "agent-redteam|Red-team and harden an AI agent|A threat model, automated and manual attacks on an agent, and the attack success rate before and after design-level defenses.|May 2027"
  "small-model-tool-calling|Fine-tune a small model to beat an API|A LoRA fine-tune of a small open model for tool calling, compared with a frontier API on quality, cost and latency.|Aug 2027"
)

printf 'Projects to create in %s:\n\n' "$code_dir"
for p in "${projects[@]}"; do
  IFS='|' read -r repo title _ start <<< "$p"
  if [ -e "$code_dir/$repo" ]; then state="exists, skip"; else state="new"; fi
  printf '  %-26s %-40s %-9s %s\n' "$repo" "$title" "$start" "($state)"
done
if [ "$mode" = "--local-only" ]; then
  printf '\nLocal folders only. Nothing is sent to GitHub.\n'
else
  printf '\nEach new one also becomes a PUBLIC repo on your GitHub account.\n'
fi
read -r -p "Continue? [y/N] " answer
case "$answer" in y | Y | yes | YES) ;; *) echo "Stopped. Nothing was created."; exit 0 ;; esac

for p in "${projects[@]}"; do
  IFS='|' read -r repo title goal start <<< "$p"
  if [ -e "$code_dir/$repo" ]; then
    printf '\n= %s already exists in %s, skipping.\n' "$repo" "$code_dir"
    continue
  fi
  printf '\n==================== %s ====================\n' "$repo"
  "$here/new_project.sh" "$repo" "$title" "$goal" "$start" $mode
done

printf '\nAll done. Check them with: %s/week0_doctor.sh --repos\n' "$here"
