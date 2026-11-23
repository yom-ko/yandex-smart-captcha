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
# simulator. The window whose title starts with the simulator's name must show its screen: in DeviceHub,
# select the simulator in the sidebar. Keep the window visible and do not move or resize it during a tap.
# Set E2E_TMP to <tmp>; the compiled clicker and a per-simulator screen-geometry cache are kept there.
# The cache is reused while the window frame is unchanged; delete e2e-ios-<simulator-id>.geom after rotating.
set -euo pipefail
udid=${1:?udid required}
cmd=${2:?command required}
tmp=${E2E_TMP:?set E2E_TMP to the run directory}
developer_dir=${DEVELOPER_DIR:?set DEVELOPER_DIR to the pinned Xcode developer directory}
if [[ -d "$developer_dir/../Applications/DeviceHub.app" ]]; then
  app=DeviceHub
  app_path="$developer_dir/../Applications/DeviceHub.app"
else
  app=Simulator
  app_path="$developer_dir/Applications/Simulator.app"
fi

# Compiles a tiny CGEvent clicker once per run.
clicker() {
  local bin="$tmp/e2e-click"
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
    app_pid=${E2E_SIMULATOR_PID:?set E2E_SIMULATOR_PID to the run-owned simulator app PID}
    [[ $app_pid =~ ^[0-9]+$ ]] || { echo "invalid simulator app PID" >&2; exit 1; }
    executable=$(cd "$app_path/Contents/MacOS" && pwd -P)/$app
    [[ $(ps -ww -p "$app_pid" -o comm=) == "$executable" ]] || { echo "simulator app PID does not match pinned Xcode" >&2; exit 1; }
    # Cache: "<pw> <ph> <window x y w h> <screen x y w h>"; reused while the window frame is unchanged,
    # which cuts a tap from several seconds to about one.
    cache="$tmp/e2e-ios-$udid.geom"
    if [[ -s $cache ]]; then
      read -r pw ph geom < "$cache"
    else
      shot_dir=$(mktemp -d "$tmp/e2e-ios.XXXXXXXX")
      shot="$shot_dir/shot.png"
      trap 'rm -f "$shot"; rmdir "$shot_dir"' EXIT
      xcrun simctl io "$udid" screenshot "$shot" >/dev/null 2>&1
      read -r pw ph < <(sips -g pixelWidth -g pixelHeight "$shot" | awk 'NR>1{printf "%s ", $2} END{print ""}')
      geom=""
    fi
    name=$(xcrun simctl list devices | sed -n "s/^ *\(.*\) ($udid) .*/\1/p")
    [[ -n $name ]] || { echo "simulator $udid not found" >&2; exit 1; }
    # Activation can move the window, so read the device-screen geometry after activating.
    out=$(osascript - "$app_path" "$app_pid" "$pw" "$ph" "$x" "$y" "$name" "$geom" <<'AS'
on run argv
  set appPath to item 1 of argv
  set appPid to (item 2 of argv) as integer
  set pw to (item 3 of argv) as real
  set ph to (item 4 of argv) as real
  set px to (item 5 of argv) as real
  set py to (item 6 of argv) as real
  set deviceName to item 7 of argv
  tell application appPath to activate
  delay 0.5
  tell application "System Events" to tell (first process whose unix id is appPid)
    -- Window titles look like "iPhone 18 Pro – iOS 27.0".
    set win to missing value
    set matches to 0
    repeat with w in windows
      set t to name of w
      if t starts with (deviceName & " " & (character id 8211)) then
        set win to w
        set matches to matches + 1
      end if
    end repeat
    if win is missing value then error "no window shows " & deviceName & "; select the test simulator"
    if matches is not 1 then error "several windows match the test simulator"
    perform action "AXRaise" of win
    set {wx, wy} to position of win
    set {ww, wh} to size of win
    set frame to (wx as text) & " " & wy & " " & ww & " " & wh
    set AppleScript's text item delimiters to " "
    set cached to text items of (item 8 of argv)
    set AppleScript's text item delimiters to ""
    if (count of cached) is 8 and ((items 1 thru 4 of cached) as text) is (wx as text) & wy & ww & wh then
      set {gx, gy, gw, gh} to {(item 5 of cached) as real, (item 6 of cached) as real, (item 7 of cached) as real, (item 8 of cached) as real}
    else
      -- The device screen is the smallest group whose aspect ratio matches the screenshot; the window and
      -- its frame can have almost the same ratio. DeviceHub nests it about six containers deep.
      set best to missing value
      set bestArea to 1.0E+9
      set bestPos to {}
      set others to false
      set level to {win}
      repeat 12 times
        set nextLevel to {}
        repeat with p in level
          repeat with g in (every UI element of p)
            set r to role of g
            if r is "AXGroup" or r is "AXSplitGroup" then
              set end of nextLevel to g
              set {gw, gh} to size of g
              if gh > 0 and (gw / gh - pw / ph) < 0.005 and (pw / ph - gw / gh) < 0.005 then
                set gp to position of g
                if gw * gh < bestArea then
                  set best to g
                  set bestArea to gw * gh
                  set bestPos to gp
                  set others to false
                else if gw * gh = bestArea and gp is not bestPos then
                  set others to true
                end if
              end if
            end if
          end repeat
        end repeat
        set level to nextLevel
        if level is {} then exit repeat
      end repeat
      if best is missing value then error "device screen not found in the " & deviceName & " window; is the simulator booted and shown?"
      if others then error "several device screens are shown; select only the test device"
      set {gx, gy} to position of best
      set {gw, gh} to size of best
    end if
  end tell
  set cx to gx + px * gw / pw
  set cy to gy + py * gh / ph
  return ((round cx) as text) & " " & ((round cy) as text) & " " & frame & " " & gx & " " & gy & " " & gw & " " & gh
end run
AS
    )
    read -r cx cy geom <<< "$out"
    echo "$pw $ph $geom" > "$cache"
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
