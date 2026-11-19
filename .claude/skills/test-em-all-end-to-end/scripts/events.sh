#!/usr/bin/env bash
# Print only sanitized E2E lines from a `flutter run` or Patrol log: event names, token presence,
# navigation hosts, the probe marker, and the Wasm marker. Never print the raw log.
#
# Usage:
#   events.sh <log>                              print the sanitized lines in order
#   events.sh <log> count <text>                 print how many times <text> occurred
#   events.sh <log> wait <text> [count] [seconds]
#                                                poll until <text> occurs <count> times (default 1, 60 s);
#                                                `+N` waits for N more than now, for example after a hot
#                                                restart, which keeps earlier events in the log
set -euo pipefail

log=${1:?log required}
pattern='called: (probe done|onCaptchaReady|onChallengeShown|onChallengeHidden|onChallengeSolved, token non-null: (true|false)|onTokenExpired|onNetworkError|onJavaScriptError|onNavigationRequest: [A-Za-z0-9.-]*)|Wasm: (true|false)'

sanitized() {
  grep -oE "$pattern" "$log" || true
}

count() {
  sanitized | grep -cF -- "$1" || true
}

case ${2:-} in
  '') sanitized; exit 0 ;;
  count) count "${3:?text required}"; exit 0 ;;
  wait) ;;
  *) echo "unknown command: $2" >&2; exit 2 ;;
esac

text=${3:?text required}
want=${4:-1}
if [[ $want == +* ]]; then want=$(($(count "$text") + ${want#+})); fi
deadline=$((SECONDS + ${5:-60}))
while :; do
  have=$(count "$text")
  if ((have >= want)); then echo "ok: $text x$have"; exit 0; fi
  if ((SECONDS >= deadline)); then echo "timeout: $text x$have of $want"; sanitized | tail -5; exit 1; fi
  sleep 1
done
