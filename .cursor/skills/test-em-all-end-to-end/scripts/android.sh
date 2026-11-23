#!/usr/bin/env bash
# Read or tap the example app on an Android device through UiAutomator and adb.
#
# Usage:
#   android.sh <device-id> state                          print Execute/Reset/Destroy/Probe states
#   android.sh <device-id> centers                        print "<name> <x> <y>" screen centers of the buttons
#                                                         and the WebView, for raw taps before readiness
#   android.sh <device-id> tap <label>                    tap a button by label
#   android.sh <device-id> wait <label> <enabled|disabled> [seconds]
#                                                         poll until the button has the state (default 30 s)
#   android.sh <device-id> checkbox                       tap the SmartCaptcha checkbox inside the WebView
#   android.sh <device-id> help                           tap the widget's `?` icon, which opens its link menu
#   android.sh <device-id> tap-webview <fx> <fy>          tap at fractions (0-1) of the WebView bounds,
#                                                         for example `tap-webview 0.5 0.9` below the widget
#   android.sh <device-id> record <seconds> <file.mp4>    record the screen (max 180 s), then pull the video
#   android.sh <device-id> rotate landscape|restore       force landscape, or restore the saved rotation settings
#
# UiAutomator sees only the WebView node, not SmartCaptcha inside it, so `checkbox` and `tap-webview`
# tap by position. Take a screenshot (`adb -s <id> exec-out screencap -p > shot.png`) to aim
# `tap-webview` and to confirm the result. Each dump takes about 1 s; for taps that must land before
# readiness, run `centers` after a previous launch, note the button center, and use
# `adb -s <id> shell input tap X Y`. To see the state before readiness, `record` the launch instead.
set -euo pipefail

device=${1:?device-id required}
cmd=${2:?command required}
dump=$(mktemp "${E2E_TMP:?set E2E_TMP to the run directory}/android-dump.XXXXXX")
trap 'rm -f "$dump"' EXIT

# Prints "<name> <enabled|disabled> <x1> <y1> <x2> <y2>" for each known button and the WebView.
read_nodes() {
  # A dump fails while the app starts or animates; report nothing so callers can poll again.
  adb -s "$device" exec-out uiautomator dump /dev/tty | sed 's#</hierarchy>.*#</hierarchy>#' > "$dump"
  python3 - "$dump" <<'PY'
import re, sys, xml.etree.ElementTree as ET
try:
    root = ET.parse(sys.argv[1]).getroot()
except ET.ParseError:
    sys.exit(0)
seen = set()
for node in root.iter('node'):
    name = node.get('content-desc') or node.get('text') or ''
    # Disabled Flutter buttons are not clickable, so also match by class.
    is_button = node.get('clickable') == 'true' or node.get('class', '').endswith('Button')
    if node.get('class') == 'android.webkit.WebView':
        name, is_button = 'WebView', True
    if name in ('Execute', 'Reset', 'Destroy', 'Probe', 'WebView') and is_button and name not in seen:
        seen.add(name)
        state = 'enabled' if node.get('enabled') == 'true' else 'disabled'
        print(name, state, *re.findall(r'\d+', node.get('bounds')))
PY
}

node_line() {
  read_nodes_retry | awk -v l="$1" '$1 == l'
}

# A dump taken during an animation can be empty, so retry a few times before giving up.
read_nodes_retry() {
  local out
  for _ in 1 2 3 4 5; do
    out=$(read_nodes)
    [[ -n $out ]] && { printf '%s\n' "$out"; return 0; }
    sleep 1
  done
  echo "no UI nodes found; is the app in the foreground?" >&2
  return 1
}

tap_webview() {
  local fx=$1 fy=$2 x y
  read -r x y < <(node_line WebView | awk -v fx="$fx" -v fy="$fy" \
    '{printf "%d %d\n", $3 + fx * ($5 - $3), $4 + fy * ($6 - $4)}') || { echo "WebView not found"; exit 1; }
  adb -s "$device" shell input tap "$x" "$y"
  echo "tapped WebView at $x,$y"
}

case "$cmd" in
  state)
    read_nodes_retry | awk '$1 != "WebView" {print $1 "=" $2}' | paste -sd ' ' -
    ;;
  centers)
    read_nodes_retry | awk '{printf "%s %d %d\n", $1, ($3 + $5) / 2, ($4 + $6) / 2}'
    ;;
  tap)
    label=${3:?label required}
    read -r _ _ x1 y1 x2 y2 < <(node_line "$label") || { echo "$label not found"; exit 1; }
    adb -s "$device" shell input tap $(((x1 + x2) / 2)) $(((y1 + y2) / 2))
    echo "tapped $label at $(((x1 + x2) / 2)),$(((y1 + y2) / 2))"
    ;;
  wait)
    label=${3:?label required}
    want=${4:?enabled or disabled required}
    deadline=$((SECONDS + ${5:-30}))
    while :; do
      line=$(read_nodes | awk '{print $1, $2}' | paste -sd ' ' -)
      if [[ " $line " == *" $label $want "* ]]; then echo "ok: $label=$want"; exit 0; fi
      if ((SECONDS >= deadline)); then echo "timeout: $line"; exit 1; fi
      sleep 1
    done
    ;;
  checkbox | help)
    # Offsets in CSS px: the checkbox is 37 right and 37 down from the WebView's top-left corner;
    # the `?` icon is 25 left of its right edge and 110 down. Converted with the screen density.
    density=$(adb -s "$device" shell wm density | awk '{v=$NF} END{print v}' | tr -d '\r')
    read -r _ _ x1 y1 x2 _ < <(node_line WebView) || { echo "WebView not found"; exit 1; }
    if [[ $cmd == checkbox ]]; then
      x=$((x1 + 37 * density / 160)); y=$((y1 + 37 * density / 160))
    else
      x=$((x2 - 25 * density / 160)); y=$((y1 + 110 * density / 160))
    fi
    adb -s "$device" shell input tap "$x" "$y"
    echo "tapped $cmd at $x,$y"
    ;;
  tap-webview)
    tap_webview "${3:?fx required}" "${4:?fy required}"
    ;;
  record)
    seconds=${3:?seconds required}
    file=${4:?file required}
    remote=$(adb -s "$device" shell mktemp /data/local/tmp/e2e-rec.XXXXXXXX | tr -d '\r')
    [[ $remote =~ ^/data/local/tmp/e2e-rec\.[A-Za-z0-9]+$ ]] || { echo "invalid recording path" >&2; exit 1; }
    trap 'adb -s "$device" shell rm -f "$remote"; rm -f "$dump"' EXIT
    adb -s "$device" shell screenrecord --time-limit "$seconds" "$remote"
    adb -s "$device" pull "$remote" "$file" >/dev/null
    adb -s "$device" shell rm -f "$remote"
    trap 'rm -f "$dump"' EXIT
    echo "saved $file (only changed frames are encoded, so it can be shorter than $seconds s)"
    ;;
  rotate)
    saved="${E2E_TMP:-${TMPDIR:-/tmp}}/e2e-rotation-$device"
    case "${3:?landscape or restore required}" in
      landscape)
        [[ -f $saved ]] || echo "$(adb -s "$device" shell settings get system accelerometer_rotation | tr -d '\r') $(adb -s "$device" shell settings get system user_rotation | tr -d '\r')" > "$saved"
        adb -s "$device" shell settings put system accelerometer_rotation 0
        adb -s "$device" shell settings put system user_rotation 1
        echo "landscape (saved: $(cat "$saved"))"
        ;;
      restore)
        read -r acc user < "$saved"
        # A single put is sometimes ignored right after rotation, so retry until both read back.
        for _ in 1 2 3; do
          adb -s "$device" shell settings put system user_rotation "$user"
          adb -s "$device" shell settings put system accelerometer_rotation "$acc"
          sleep 1
          now="$(adb -s "$device" shell settings get system accelerometer_rotation | tr -d '\r') $(adb -s "$device" shell settings get system user_rotation | tr -d '\r')"
          [[ $now == "$acc $user" ]] && { rm -f "$saved"; echo "restored: $now"; exit 0; }
        done
        echo "restore failed: now $now, expected $acc $user"; exit 1
        ;;
      *) echo "rotate needs landscape or restore" >&2; exit 2 ;;
    esac
    ;;
  *)
    echo "unknown command: $cmd" >&2
    exit 2
    ;;
esac
