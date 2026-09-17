#!/usr/bin/env bash
#
# Generates AI-agent instruction/rule/skill files for Claude, Cursor,
# and GitHub Copilot from the single source of truth in .agents/.
#
# .agents/project.md   -> AGENTS.md, .claude/CLAUDE.md, .github/copilot-instructions.md
# .agents/rules/<f>    -> .claude/rules/<f>.md, .cursor/rules/<f>.mdc, .github/instructions/<f>.instructions.md
# .agents/skills/<dir> -> .claude/skills/<dir>, .cursor/skills/<dir>, .github/skills/<dir>
#
# All generated files/directories are created if missing and fully
# overwritten otherwise, with a "do not edit" header prepended.

set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR
readonly AGENTS_DIR="${ROOT_DIR}/.agents"
readonly HEADER="<!-- GENERATED FILE. DO NOT EDIT MANUALLY! Edit source in .agents/ and run build-agent-context.sh -->"

log_info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
log_ok() { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
log_error() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; }

trap 'log_error "Failed at line ${LINENO}."' ERR

# Writes $1 (source file) into $2 (destination file), prefixed with the
# generated-file header, creating parent directories as needed.
write_target_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  { printf '%s\n\n' "$HEADER"; cat "$src"; } >"$dest"
  log_ok "${dest#"$ROOT_DIR"/}"
}

sync_project_overview() {
  local src="${AGENTS_DIR}/project.md"
  [[ -f "$src" ]] || { log_error "Source file not found: ${src#"$ROOT_DIR"/}"; exit 1; }

  log_info "Syncing project description"
  local dest
  for dest in \
    "${ROOT_DIR}/AGENTS.md" \
    "${ROOT_DIR}/.claude/CLAUDE.md" \
    "${ROOT_DIR}/.github/copilot-instructions.md"; do
    write_target_file "$src" "$dest"
  done
}

sync_rules() {
  local rules_dir="${AGENTS_DIR}/rules" rules=("${AGENTS_DIR}/rules"/*)
  ((${#rules[@]})) || { log_info "No rules found in ${rules_dir#"$ROOT_DIR"/}, skipping"; return; }

  log_info "Syncing ${#rules[@]} rule(s)"
  rm -rf "${ROOT_DIR}/.claude/rules" "${ROOT_DIR}/.cursor/rules" "${ROOT_DIR}/.github/instructions"
  local rule name
  for rule in "${rules[@]}"; do
    [[ -f "$rule" ]] || continue
    name="$(basename "${rule%.*}")"
    write_target_file "$rule" "${ROOT_DIR}/.claude/rules/${name}.md"
    write_target_file "$rule" "${ROOT_DIR}/.cursor/rules/${name}.mdc"
    write_target_file "$rule" "${ROOT_DIR}/.github/instructions/${name}.instructions.md"
  done
}

sync_skills() {
  local skills_dir="${AGENTS_DIR}/skills" skills=("${AGENTS_DIR}/skills"/*/)
  ((${#skills[@]})) || { log_info "No skills found in ${skills_dir#"$ROOT_DIR"/}, skipping"; return; }

  log_info "Syncing ${#skills[@]} skill(s)"
  local skill_dir skill_name target_root dest_dir file rel_path
  for skill_dir in "${skills[@]}"; do
    skill_name="$(basename "$skill_dir")"
    for target_root in "${ROOT_DIR}/.claude/skills" "${ROOT_DIR}/.cursor/skills" "${ROOT_DIR}/.github/skills"; do
      dest_dir="${target_root}/${skill_name}"
      rm -rf "$dest_dir"
      while IFS= read -r -d '' file; do
        rel_path="${file#"$skill_dir"}"
        write_target_file "$file" "${dest_dir}/${rel_path}"
      done < <(find "$skill_dir" -type f -print0)
    done
  done
}

main() {
  [[ -d "$AGENTS_DIR" ]] || { log_error ".agents directory not found: ${AGENTS_DIR}"; exit 1; }

  sync_project_overview
  sync_rules
  sync_skills

  log_info "All agent context files generated successfully."
}

main "$@"
