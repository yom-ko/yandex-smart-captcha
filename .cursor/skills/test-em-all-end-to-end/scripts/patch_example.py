#!/usr/bin/env python3
"""Apply or change the temporary E2E edits in the snapshot's example/lib/main.dart.

Usage:
  python3 patch_example.py apply <snapshot>/example/lib/main.dart
  python3 patch_example.py set <snapshot>/example/lib/main.dart <switch> <value>

Switches (hot restart applies a change; a debug --wasm run must be relaunched):
  invisible  true|false  useInvisibleMode
  bad_key    true|false  use 'invalid-key' instead of CLIENT_KEY
  language   en|ru|...   any CaptchaLanguage value name
  block_nav  true|false  block every main-frame navigation in onNavigationRequest

`apply` adds, marked with E2E-TEMP comments:
  - a sanitized event history ("E2E: ..." above the buttons) fed by an allowlisted debugPrint hook;
  - a startup "Wasm: true|false" line;
  - token-free onChallengeSolved and host-only onNavigationRequest logs;
  - an always-enabled "Probe" button that calls execute, reset, and destroy and logs "called: probe done".

Every anchor must match exactly once; otherwise nothing is written and the script exits with 1.
"""

import re
import sys

SWITCHES = {
    'invisible': ('e2eInvisible', r'true|false'),
    'bad_key': ('e2eBadKey', r'true|false'),
    'language': ('e2eLanguage', r'[a-z]+'),
    'block_nav': ('e2eBlockNavigation', r'true|false'),
}

MAIN_HEADER = r"""// E2E-TEMP: option switches; change them with patch_example.py set.
const e2eInvisible = false;
const e2eBadKey = false;
const e2eLanguage = CaptchaLanguage.en;
const e2eBlockNavigation = false;

// E2E-TEMP: sanitized on-screen event history.
final e2eEvents = ValueNotifier<List<String>>([]);
final _e2eAllowed = RegExp(
  r'^(called: (onCaptchaReady|onChallengeShown|onChallengeHidden|onTokenExpired'
  r'|onNetworkError|onJavaScriptError|onNavigationRequest|probe done)'
  r'|called: onChallengeSolved, token non-null: (true|false)|Wasm: (true|false))',
);

void main() {
  // E2E-TEMP: mirror allowlisted log lines into the event history.
  final printLine = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    final match = _e2eAllowed.firstMatch(message ?? '');
    if (match != null) e2eEvents.value = [...e2eEvents.value, match.group(0)!];
    printLine(message, wrapWidth: wrapWidth);
  };
  debugPrint('Wasm: ${const bool.fromEnvironment('dart.tool.dart2wasm')}');
  runApp(const App());
}"""

EVENT_HISTORY = """            // E2E-TEMP: event history.
            ValueListenableBuilder<List<String>>(
              valueListenable: e2eEvents,
              builder: (_, events, _) => Text(
                'E2E: ${events.join(' | ')}',
                style: const TextStyle(fontSize: 9),
              ),
            ),
"""

PROBE_BUTTON = """                    // E2E-TEMP: always-enabled controller probe.
                    TextButton(
                      onPressed: () async {
                        await _controller.execute();
                        await _controller.reset();
                        await _controller.destroy();
                        debugPrint('called: probe done');
                      },
                      child: const Text('Probe'),
                    ),
"""

EDITS = [
    ("void main() {\n  runApp(const App());\n}", MAIN_HEADER),
    (
        "    clientKey: clientKey,\n    language: CaptchaLanguage.en,\n",
        "    clientKey: e2eBadKey ? 'invalid-key' : clientKey,\n    language: e2eLanguage,\n",
    ),
    ("    // useInvisibleMode: true,\n", "    useInvisibleMode: e2eInvisible,\n"),
    (
        "debugPrint('called: onNavigationRequest: $url');",
        "debugPrint('called: onNavigationRequest: ${Uri.tryParse(url)?.host}');",
    ),
    (
        "return !url.contains('yandex.cloud');",
        "return !e2eBlockNavigation && !url.contains('yandex.cloud');",
    ),
    (
        "debugPrint('called: onChallengeSolved with token: $token');",
        "debugPrint('called: onChallengeSolved, token non-null: ${token != null}');",
    ),
    (
        "            Padding(\n              padding: const EdgeInsets.all(16),\n",
        EVENT_HISTORY + "            Padding(\n              padding: const EdgeInsets.all(16),\n",
    ),
    (
        "                    FilledButton.tonalIcon(\n",
        PROBE_BUTTON + "                    FilledButton.tonalIcon(\n",
    ),
]


def fail(message):
    print(f'error: {message}', file=sys.stderr)
    sys.exit(1)


def apply(source):
    if 'E2E-TEMP' in source:
        fail('the file is already patched')
    for old, new in EDITS:
        count = source.count(old)
        if count != 1:
            fail(f'expected one match, found {count}: {old.strip().splitlines()[0]!r}')
        source = source.replace(old, new)
    return source


def set_switch(source, name, value):
    if name not in SWITCHES:
        fail(f'unknown switch {name!r}; use one of {", ".join(SWITCHES)}')
    const, allowed = SWITCHES[name]
    if not re.fullmatch(allowed, value):
        fail(f'invalid value {value!r} for {name}')
    if name == 'language':
        value = f'CaptchaLanguage.{value}'
    source, count = re.subn(rf'^const {const} = .*;$', f'const {const} = {value};', source, flags=re.M)
    if count != 1:
        fail(f'switch {const} not found; run apply first')
    return source


def main(argv):
    if len(argv) == 3 and argv[1] == 'apply':
        path, update = argv[2], apply
    elif len(argv) == 5 and argv[1] == 'set':
        path, update = argv[2], lambda s: set_switch(s, argv[3], argv[4])
    else:
        fail('usage: patch_example.py apply <main.dart> | set <main.dart> <switch> <value>')
    with open(path, encoding='utf-8') as f:
        source = f.read()
    updated = update(source)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(updated)
    print('ok')


if __name__ == '__main__':
    main(sys.argv)
