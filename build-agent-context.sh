#!/usr/bin/env bash
#
# Generates AI-agent instruction/rule/skill files for Claude, Cursor, and
# GitHub Copilot from the single source of truth in .agents/.
#
# .agents/project.md   -> AGENTS.md, .claude/CLAUDE.md, .github/copilot-instructions.md
# .agents/rules/<f>    -> .claude/rules/<f>.md, .cursor/rules/<f>.mdc, .github/instructions/<f>.instructions.md
# .agents/skills/<dir> -> .claude/skills/<dir>, .cursor/skills/<dir>, .github/skills/<dir>
#
# - Generated files/directories are created if missing, and fully overwritten otherwise.
# - The "do not edit" header is only added to hub files (AGENTS.md, CLAUDE.md, copilot-instructions.md).
# - Rules and skills are copied as-is since their frontmatter must stay on the first line,
#   and skills may contain scripts whose permissions/content must be preserved.

set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR
readonly AGENTS_DIR="${ROOT_DIR}/.agents"
readonly HEADER="<!-- GENERATED FILE. DO NOT EDIT MANUALLY! Edit source in .agents/ and run build-agent-context.sh -->"

# Destination files/directories this generator owns, used to detect files a
# run removed (e.g. a deleted rule/skill) so those deletions get staged too.
readonly MANAGED_TARGETS=(
  "AGENTS.md"
  ".claude/CLAUDE.md"
  ".claude/rules"
  ".claude/skills"
  ".cursor/rules"
  ".cursor/skills"
  ".github/copilot-instructions.md"
  ".github/instructions"
  ".github/skills"
)

EXISTING_FILES=()
GENERATED_FILES=()
LIST_AFFECTED_FILES=false

log_info() {
  "$LIST_AFFECTED_FILES" || printf '\033[1;34m==>\033[0m %s\n' "$*"
}
log_ok() {
  "$LIST_AFFECTED_FILES" || printf '\033[1;32m  ✓\033[0m %s\n' "$*"
}
log_error() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; }

trap 'log_error "Failed at line ${LINENO}."' ERR

# Records $1 (an already-written destination path) as generated and logs it.
track_generated() {
  local dest="$1"
  GENERATED_FILES+=("${dest#"$ROOT_DIR"/}")
  log_ok "${dest#"$ROOT_DIR"/}"
}

# Writes $1 (source) into $2 (destination hub file) with the defined header.
write_hub_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  { printf '%s\n\n' "$HEADER"; cat "$src"; } >"$dest"
  track_generated "$dest"
}

# Copies $1 (source rule file) to $2 unmodified. No header is injected.
write_rule_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  track_generated "$dest"
}

# Snapshots every file under the managed targets before generation runs.
capture_existing_files() {
  local target path file
  for target in "${MANAGED_TARGETS[@]}"; do
    path="${ROOT_DIR}/${target}"
    if [[ -f "$path" ]]; then
      EXISTING_FILES+=("$target")
    elif [[ -d "$path" ]]; then
      while IFS= read -r -d '' file; do
        EXISTING_FILES+=("${file#"$ROOT_DIR"/}")
      done < <(find "$path" -type f -print0)
    fi
  done
}

# Prints every managed file this run touched: created, modified, deleted.
print_affected_files() {
  printf '%s\n' "${EXISTING_FILES[@]}" "${GENERATED_FILES[@]}" | sort -u | tr '\n' '\0'
}

usage() { printf 'Usage: %s [--list-affected-files]\n' "$(basename "$0")"; }

parse_args() {
  case "${1:-}" in
    "")
      ;;
    --list-affected-files)
      LIST_AFFECTED_FILES=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac

  (($# <= 1)) || {
    log_error "Expected at most one option"
    usage >&2
    exit 2
  }
}

sync_project() {
  local src="${AGENTS_DIR}/project.md"
  [[ -f "$src" ]] || { log_error "Source file not found: ${src#"$ROOT_DIR"/}"; exit 1; }

  log_info "Syncing project overview"
  local dest
  for dest in \
    "${ROOT_DIR}/AGENTS.md" \
    "${ROOT_DIR}/.claude/CLAUDE.md" \
    "${ROOT_DIR}/.github/copilot-instructions.md"; do
    write_hub_file "$src" "$dest"
  done
}

sync_rules() {
  local rules_dir="${AGENTS_DIR}/rules" rules=("${AGENTS_DIR}/rules"/*)
  rm -rf "${ROOT_DIR}/.claude/rules" "${ROOT_DIR}/.cursor/rules" "${ROOT_DIR}/.github/instructions"
  ((${#rules[@]})) || { log_info "No rules found in ${rules_dir#"$ROOT_DIR"/}, skipping"; return; }

  log_info "Syncing ${#rules[@]} rule(s)"
  local rule name
  for rule in "${rules[@]}"; do
    [[ -f "$rule" ]] || continue
    name="$(basename "${rule%.*}")"
    write_rule_file "$rule" "${ROOT_DIR}/.claude/rules/${name}.md"
    write_rule_file "$rule" "${ROOT_DIR}/.cursor/rules/${name}.mdc"
    write_rule_file "$rule" "${ROOT_DIR}/.github/instructions/${name}.instructions.md"
  done
}

sync_skills() {
  local skills_dir="${AGENTS_DIR}/skills" skills=("${AGENTS_DIR}/skills"/*/)
  local targets=("${ROOT_DIR}/.claude/skills" "${ROOT_DIR}/.cursor/skills" "${ROOT_DIR}/.github/skills")
  rm -rf "${targets[@]}"
  ((${#skills[@]})) || { log_info "No skills found in ${skills_dir#"$ROOT_DIR"/}, skipping"; return; }

  log_info "Syncing ${#skills[@]} skill(s)"
  local skill_dir skill_name target_root dest_dir file
  for skill_dir in "${skills[@]}"; do
    skill_name="$(basename "$skill_dir")"
    for target_root in "${targets[@]}"; do
      dest_dir="${target_root}/${skill_name}"
      mkdir -p "$dest_dir"
      cp -a "${skill_dir}." "$dest_dir"
      while IFS= read -r -d '' file; do
        track_generated "$file"
      done < <(find "$dest_dir" -type f -print0)
    done
  done
}

main() {
  parse_args "$@"
  [[ -d "$AGENTS_DIR" ]] || { log_error ".agents directory not found: ${AGENTS_DIR}"; exit 1; }

  capture_existing_files
  sync_project
  sync_rules
  sync_skills

  log_info "All agent context files generated successfully."
  if "$LIST_AFFECTED_FILES"; then
    print_affected_files
  fi
}

main "$@"
