#!/usr/bin/env bash
# Create a working-tree snapshot without copying the live-key file.
# Usage: snapshot.sh <absolute-run-directory> [additional-sensitive-path ...]
# Run from the repository root. Additional paths must be repository-relative.
set -euo pipefail
umask 077

tmp=${1:?run directory required}
shift
[[ $tmp == /* && -d $tmp && ! -L $tmp ]] || { echo "invalid run directory" >&2; exit 1; }
[[ ! -e $tmp/index && ! -e $tmp/objects && ! -e $tmp/snapshot ]] || { echo "run directory already contains snapshot files" >&2; exit 1; }
index=$(git rev-parse --path-format=absolute --git-path index)
objects=$(git rev-parse --path-format=absolute --git-path objects)
[[ -f $index ]] || { echo "repository index not found" >&2; exit 1; }

sensitive=(example/.env)
for path in "$@"; do
  [[ -n $path && $path != /* && $path != *..* ]] || { echo "invalid sensitive path" >&2; exit 1; }
  while [[ $path == ./* ]]; do path=${path#./}; done
  while [[ $path == */ ]]; do path=${path%/}; done
  [[ -n $path && $path != . && $path != -* && $path != *//* && $path != */./* && $path != */. ]] ||
    { echo "invalid sensitive path" >&2; exit 1; }
  sensitive+=("$path")
done

mkdir "$tmp/objects"
cp "$index" "$tmp/index"
export GIT_INDEX_FILE="$tmp/index"
export GIT_OBJECT_DIRECTORY="$tmp/objects"
export GIT_ALTERNATE_OBJECT_DIRECTORIES="$objects"
git --literal-pathspecs ls-files -z -- "${sensitive[@]}" | git update-index --force-remove -z --stdin
git ls-files -z --cached --others --exclude-standard |
  python3 -c '
import os
import sys

excluded = [os.fsencode(path) for path in sys.argv[1:]]
paths = sys.stdin.buffer.read().split(b"\0")
sys.stdout.buffer.write(b"".join(
    path + b"\0" for path in paths if path and not any(
        path == item or path.startswith(item + b"/") for item in excluded
    )
))
' "${sensitive[@]}" |
  git --literal-pathspecs add -A --pathspec-from-file=- --pathspec-file-nul
git checkout-index -a --prefix="$tmp/snapshot/"
[[ -f $tmp/snapshot/pubspec.yaml && ! -e $tmp/snapshot/example/.env ]] || { echo "snapshot verification failed" >&2; exit 1; }
echo SNAPSHOT_OK
