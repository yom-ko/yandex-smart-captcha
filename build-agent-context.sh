#!/usr/bin/env bash
#
# Generates AI agent instruction/rule/skill files for Claude, Cursor, and
# GitHub Copilot from the single source of truth in .agents/.
#
# .agents/project.md   -> AGENTS.md, .claude/CLAUDE.md, .github/copilot-instructions.md
# .agents/rules/<f>.md -> .claude/rules/<f>.md, .cursor/rules/<f>.mdc, .github/instructions/<f>.instructions.md
# .agents/skills/<dir> -> .claude/skills/<dir>, .cursor/skills/<dir>, .github/skills/<dir>
#
# - Build everything in a temporary tree before modifying the repository.
# - Fully own MANAGED_TARGETS: replace them and remove stale contents on every run.
# - Install in two phases and roll back completed swaps on a later failure.
# - Ignore hidden top-level entries in rules and skills.
# - Require rules to be .md files and skills to be directories containing SKILL.md.
# - Restrict rule and skill names to lowercase ASCII letters, digits, '.', '_' and '-';
#   names must start with a letter or digit and must not end with '.'.
# - Reject any symlinks under .agents/.
# - Add the "do not edit" header only to hub files.
# - Copy rules as-is and preserve skill contents and executable bits.
# - Stay compatible with Bash 3.2 (the macOS system Bash).

set -Eeuo pipefail
export LC_ALL=C
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR
readonly AGENTS_DIR="${ROOT_DIR}/.agents"
readonly HEADER="<!-- GENERATED FILE. DO NOT EDIT MANUALLY! Edit source in .agents/ and run build-agent-context.sh -->"
readonly JUNK_NAME=".DS_Store"
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

MODE="generate"
QUIET=false
BUILD_DIR=""
INSTALL_PHASE=""
SWAP_COUNT=0

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly C_INFO=$'\033[1;34m' C_OK=$'\033[1;32m' C_RESET=$'\033[0m'
else
  readonly C_INFO="" C_OK="" C_RESET=""
fi
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  readonly C_ERR=$'\033[1;31m' C_WARN=$'\033[1;33m' C_ERR_RESET=$'\033[0m'
else
  readonly C_ERR="" C_WARN="" C_ERR_RESET=""
fi

log_info() { [[ "$QUIET" == true ]] || printf '%s==>%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
log_ok() { [[ "$QUIET" == true ]] || printf '%s  ✓%s %s\n' "$C_OK" "$C_RESET" "$*"; }
log_warn() { printf '%sWARNING:%s %s\n' "$C_WARN" "$C_ERR_RESET" "$*" >&2; }
log_error() { printf '%sERROR:%s %s\n' "$C_ERR" "$C_ERR_RESET" "$*" >&2; }
die() { log_error "$*"; exit 1; }

cleanup() {
  set +e
  trap - ERR
  case "$INSTALL_PHASE" in
    swapping)
      rollback_install
      discard_install_leftovers new
      discard_install_leftovers old
      ;;
    preparing)
      discard_install_leftovers new
      ;;
    committed)
      discard_install_leftovers old
      ;;
  esac
  [[ -z "$BUILD_DIR" ]] || rm -rf "$BUILD_DIR"
}

on_error() {
  ((BASH_SUBSHELL == 0)) || return 0
  log_error "Failed at line $2: $3 (exit $1)"
}
trap 'on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
trap cleanup EXIT

rel() { printf '%s' "${1#"$ROOT_DIR"/}"; }
built_rel() { printf '%s' "${1#"$BUILD_DIR"/}"; }

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--check | --print-managed-targets] [-q|--quiet] [-h|--help]

  (default)                Regenerate all managed agent context files.
  --check                  Do not modify anything; exit 1 if generated files
                           differ from what .agents/ would produce (useful for CI).
  --print-managed-targets  Print the repo-relative paths owned by this script,
                           one per line.
  -q, --quiet              Suppress progress output.
  -h, --help               Show this help.
USAGE
}

set_mode() {
  [[ "$MODE" == "generate" || "$MODE" == "$1" ]] || {
    log_error "Options --check and --print-managed-targets are mutually exclusive"
    usage >&2
    exit 2
  }
  MODE="$1"
}

parse_args() {
  while (($#)); do
    case "$1" in
      --check) set_mode check ;;
      --print-managed-targets) set_mode print-targets ;;
      -q|--quiet) QUIET=true ;;
      -h|--help) usage; exit 0 ;;
      *)
        log_error "Unknown option: $1"
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

validate_name() {
  local kind="$1" name="$2" path="$3"

  [[ "$name" =~ ^[a-z0-9][a-z0-9._-]*$ ]] ||
    die "$kind name must contain only lowercase ASCII letters, digits, '.', '_' and '-': $(rel "$path")"

  [[ "$name" != *. ]] ||
    die "$kind name must not end with '.': $(rel "$path")"
}

write_hub_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  { printf '%s\n\n' "$HEADER"; cat "$src"; } >"$dest"
  log_ok "$(built_rel "$dest")"
}

write_rule_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  log_ok "$(built_rel "$dest")"
}

build_project() {
  local src="${AGENTS_DIR}/project.md"
  [[ -f "$src" ]] || die "Source file not found: $(rel "$src")"

  log_info "Building project intro"
  write_hub_file "$src" "${BUILD_DIR}/AGENTS.md"
  write_hub_file "$src" "${BUILD_DIR}/.claude/CLAUDE.md"
  write_hub_file "$src" "${BUILD_DIR}/.github/copilot-instructions.md"
}

build_rules() {
  local rules=("${AGENTS_DIR}/rules"/*)
  if ((${#rules[@]} == 0)); then
    log_info "No rules found in $(rel "${AGENTS_DIR}/rules"), so no rule outputs are generated"
    return
  fi

  local rule name
  for rule in "${rules[@]}"; do
    [[ -f "$rule" && "$rule" == *.md ]] ||
      die "Rules must be regular '.md' files: $(rel "$rule")"

    name="$(basename "$rule" .md)"
    validate_name "Rule" "$name" "$rule"
  done

  log_info "Building ${#rules[@]} rule(s)"
  for rule in "${rules[@]}"; do
    name="$(basename "$rule" .md)"
    write_rule_file "$rule" "${BUILD_DIR}/.claude/rules/${name}.md"
    write_rule_file "$rule" "${BUILD_DIR}/.cursor/rules/${name}.mdc"
    write_rule_file "$rule" "${BUILD_DIR}/.github/instructions/${name}.instructions.md"
  done
}

build_skills() {
  local skills=("${AGENTS_DIR}/skills"/*)
  if ((${#skills[@]} == 0)); then
    log_info "No skills found in $(rel "${AGENTS_DIR}/skills"), so no skill outputs are generated"
    return
  fi

  local skill_dir
  for skill_dir in "${skills[@]}"; do
    [[ -d "$skill_dir" && -f "${skill_dir}/SKILL.md" ]] ||
      die "Skills must be directories containing SKILL.md: $(rel "$skill_dir")"

    validate_name "Skill" "$(basename "$skill_dir")" "$skill_dir"
  done

  log_info "Building ${#skills[@]} skill(s)"
  local skill_name provider dest_dir file
  for skill_dir in "${skills[@]}"; do
    skill_name="$(basename "$skill_dir")"

    for provider in .claude .cursor .github; do
      dest_dir="${BUILD_DIR}/${provider}/skills/${skill_name}"
      mkdir -p "$dest_dir"
      cp -Rp "${skill_dir}/." "$dest_dir"
      find "$dest_dir" -name "$JUNK_NAME" -type f -delete

      while IFS= read -r file; do
        log_ok "$(built_rel "$file")"
      done < <(find "$dest_dir" ! -type d | LC_ALL=C sort)
    done
  done
}

executable_files() {
  (cd "$1" && find . -type f -perm -u+x | LC_ALL=C sort)
}

target_up_to_date() {
  local built="${BUILD_DIR}/$1" current="${ROOT_DIR}/$1"

  if [[ ! -e "$built" && ! -L "$built" ]]; then
    [[ ! -e "$current" && ! -L "$current" ]]
  elif [[ -d "$built" ]]; then
    [[ -d "$current" && ! -L "$current" ]] &&
      diff -rq -x "$JUNK_NAME" "$built" "$current" >/dev/null 2>&1 &&
      [[ "$(executable_files "$built")" == "$(executable_files "$current")" ]]
  else
    [[ -f "$current" && ! -L "$current" ]] &&
      cmp -s "$built" "$current"
  fi
}

check_outputs() {
  local target stale=()

  for target in "${MANAGED_TARGETS[@]}"; do
    target_up_to_date "$target" || stale+=("$target")
  done

  if ((${#stale[@]})); then
    log_error "Generated agent context is out of date:"
    printf '  %s\n' "${stale[@]}" >&2
    printf 'Run ./%s and commit the result.\n' "$(basename "$0")" >&2
    exit 1
  fi

  log_info "Generated agent context is up to date."
}

path_exists() { [[ -e "$1" || -L "$1" ]]; }

assert_agents_have_no_symlinks() {
  local link

  while IFS= read -r -d '' link; do
    die "Symlinks are not allowed under .agents: $(rel "$link")"
  done < <(find -P "$AGENTS_DIR" -type l -print0)
}

assert_managed_parents_are_real() {
  local target dir

  for target in "${MANAGED_TARGETS[@]}"; do
    dir="$(dirname "$target")"

    while [[ "$dir" != "." ]]; do
      [[ ! -L "${ROOT_DIR}/${dir}" ]] ||
        die "Managed targets must not be inside a symlinked directory: ${dir}"
      dir="$(dirname "$dir")"
    done
  done
}

discard_install_leftovers() {
  local target

  for target in "${MANAGED_TARGETS[@]}"; do
    rm -rf "${ROOT_DIR:?}/${target}.$1"
  done
}

prepare_target() {
  local built="${BUILD_DIR}/$1" dest="${ROOT_DIR}/$1"

  if path_exists "$built"; then
    mkdir -p "$(dirname "$dest")"
    cp -Rp "$built" "${dest}.new"
  fi
}

swap_target() {
  local dest="${ROOT_DIR}/$1"

  if path_exists "$dest"; then
    mv "$dest" "${dest}.old"
  fi

  if path_exists "${dest}.new"; then
    mv "${dest}.new" "$dest"
  fi
}

rollback_install() {
  local i target dest

  for ((i = SWAP_COUNT - 1; i >= 0; i--)); do
    target="${MANAGED_TARGETS[i]}"
    dest="${ROOT_DIR}/${target}"

    if path_exists "${dest}.old"; then
      rm -rf "${dest:?}"
      mv "${dest}.old" "$dest"
    elif ! path_exists "${dest}.new" && path_exists "${BUILD_DIR}/${target}"; then
      rm -rf "${dest:?}"
    fi
  done
}

report_install_leftovers() {
  local target suffix leftovers=()

  for target in "${MANAGED_TARGETS[@]}"; do
    for suffix in new old; do
      if path_exists "${ROOT_DIR}/${target}.${suffix}"; then
        leftovers+=("${target}.${suffix}")
      fi
    done
  done

  if ((${#leftovers[@]})); then
    log_warn "Discarding leftovers of an interrupted run: ${leftovers[*]}"
  fi
}

install_outputs() {
  report_install_leftovers
  discard_install_leftovers new
  discard_install_leftovers old

  local target
  INSTALL_PHASE=preparing

  for target in "${MANAGED_TARGETS[@]}"; do
    prepare_target "$target"
  done

  INSTALL_PHASE=swapping

  for target in "${MANAGED_TARGETS[@]}"; do
    SWAP_COUNT=$((SWAP_COUNT + 1))
    swap_target "$target"
  done

  INSTALL_PHASE=committed
  discard_install_leftovers old
}

main() {
  parse_args "$@"

  if [[ "$MODE" == "print-targets" ]]; then
    printf '%s\n' "${MANAGED_TARGETS[@]}"
    return
  fi

  [[ -d "$AGENTS_DIR" && ! -L "$AGENTS_DIR" ]] ||
    die ".agents must be a real directory: ${AGENTS_DIR}"

  assert_agents_have_no_symlinks
  assert_managed_parents_are_real

  BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/build-agent-context.XXXXXX")"

  [[ "$MODE" != "check" ]] || QUIET=true

  build_project
  build_rules
  build_skills

  if [[ "$MODE" == "check" ]]; then
    check_outputs
    return
  fi

  install_outputs
  log_info "All agent context files generated successfully."
}

main "$@"
