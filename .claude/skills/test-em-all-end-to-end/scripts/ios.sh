#!/usr/bin/env bash
# Screenshot, tap, or record an iOS simulator shown in DeviceHub (Xcode 27+) or Simulator.app (macOS).
#
# Usage:
#   ios.sh <simulator-id> shot <file.png>              save a screenshot; prints its pixel width and height
#   ios.sh <simulator-id> tap <x> <y>                  tap at pixel coordinates read from a `shot`
#   ios.sh <simulator-id> record <seconds> <file.mp4>  record the simulator screen
#
# `tap` needs macOS Accessibility permission for the app running this script (ask before the user grants
# it, and ask them to revoke it during cleanup). It brings the simulator window to the front, finds the
# device screen in it, and posts real mouse events, because System Events clicks do not reach the
# simulator. Keep the window visible and do not move or resize it during a tap. Set E2E_TMP to <tmp>;
# the compiled clicker is kept there.
set -euo pipefail
udid=${1:?udid required}
cmd=${2:?command required}
app=DeviceHub
[[ -d "$(xcode-select -p)/../Applications/DeviceHub.app" ]] || app=Simulator

# Compiles a tiny CGEvent clicker once per E2E_TMP (or TMPDIR).
clicker() {
  local bin="${E2E_TMP:-${TMPDIR:-/tmp}}/e2e-click"
  if [[ ! -x $bin ]]; then
    cat > "$bin.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let p = CGPoint(x: Double(CommandLine.arguments[1])!, y: Double(CommandLine.arguments[2])!)
for type in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
  CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: p, mouseButton: .left)!.post(tap: .cghidEventTap)
  usleep(80_000)
}
SWIFT
    swiftc -O "$bin.swift" -o "$bin" 2>/dev/null
  fi
  echo "$bin"
}

case "$cmd" in
  shot)
    xcrun simctl io "$udid" screenshot "${3:?file required}" >/dev/null 2>&1
    sips -g pixelWidth -g pixelHeight "$3" | awk 'NR>1{printf "%s ", $2} END{print ""}'
    ;;
  tap)
    x=${3:?x required}; y=${4:?y required}
    shot=$(mktemp -t e2e-ios).png
    trap 'rm -f "$shot"' EXIT
    xcrun simctl io "$udid" screenshot "$shot" >/dev/null 2>&1
    read -r pw ph < <(sips -g pixelWidth -g pixelHeight "$shot" | awk 'NR>1{printf "%s ", $2} END{print ""}')
    # Activation can move the window, so read the device-screen geometry after activating.
    read -r cx cy < <(osascript - "$app" "$pw" "$ph" "$x" "$y" <<'AS'
on run argv
  set appName to item 1 of argv
  set pw to (item 2 of argv) as real
  set ph to (item 3 of argv) as real
  set px to (item 4 of argv) as real
  set py to (item 5 of argv) as real
  tell application appName to activate
  delay 0.5
  tell application "System Events" to tell process appName
    -- The device screen is the smallest group whose aspect ratio matches the screenshot;
    -- the window itself can have almost the same aspect ratio.
    set best to missing value
    set bestArea to 1.0E+9
    set candidates to (every group of window 1) & (every group of group 1 of window 1)
    repeat with g in candidates
      set {gw, gh} to size of g
      if gh > 0 and gw * gh < bestArea and (gw / gh - pw / ph) < 0.005 and (pw / ph - gw / gh) < 0.005 then
        set best to g
        set bestArea to gw * gh
      end if
    end repeat
    if best is missing value then error "device screen not found"
    set {gx, gy} to position of best
    set {gw, gh} to size of best
  end tell
  set cx to gx + px * gw / pw
  set cy to gy + py * gh / ph
  return ((round cx) as text) & " " & ((round cy) as text)
end run
AS
    )
    # System Events clicks do not reach the simulator, so post real mouse events.
    "$(clicker)" "$cx" "$cy"
    echo "tapped $x,$y at screen $cx,$cy"
    ;;
  record)
    seconds=${3:?seconds required}
    file=${4:?file required}
    xcrun simctl io "$udid" recordVideo --codec h264 --force "$file" >/dev/null 2>&1 &
    rec=$!
    sleep "$seconds"
    kill -INT "$rec"
    wait "$rec" || true
    echo "saved $file"
    ;;
  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
