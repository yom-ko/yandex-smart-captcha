#!/usr/bin/env python3
"""Print Patrol test names and outcomes from result files, then a count line.

For each failed case, the first line of its failure message follows as `  reason: ...`, with
SmartCaptcha keys and other long opaque strings redacted and the line shortened.

Usage:
  python3 patrol_results.py android <snapshot>/example/build/app/outputs/androidTest-results/connected
  python3 patrol_results.py ios <tmp>/ios-tests-<target>-<attempt>.json

The iOS input is the output of `xcrun xcresulttool get test-results tests --path <xcresult>`.
Exits with 1 when no test cases are found.
"""

import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET


def reason(text):
    lines = [line.strip() for line in (text or '').splitlines() if line.strip()]
    if not lines:
        return None
    line = re.sub(r'ysc[12]_\S+', '[redacted]', lines[0])
    line = re.sub(r'[A-Za-z0-9_\-.=+/]{40,}', '[redacted]', line)
    return line[:200]


def android(directory):
    for path in sorted(glob.glob(os.path.join(directory, '**', '*.xml'), recursive=True)):
        for case in ET.parse(path).getroot().iter('testcase'):
            failure = case.find('failure')
            if failure is None:
                failure = case.find('error')
            if failure is not None:
                text = failure.get('message') or failure.text
                yield case.get('name'), 'Failed', reason(text)
            elif case.find('skipped') is not None:
                yield case.get('name'), 'Skipped', None
            else:
                yield case.get('name'), 'Passed', None


def ios(path):
    def walk(node):
        if node.get('nodeType') == 'Test Case':
            messages = [c.get('name') for c in node.get('children', []) if c.get('nodeType') == 'Failure Message']
            yield node.get('name'), node.get('result'), reason(messages[0]) if messages else None
        for child in node.get('children', []):
            yield from walk(child)

    with open(path, encoding='utf-8') as f:
        for node in json.load(f).get('testNodes', []):
            yield from walk(node)


def main(argv):
    if len(argv) != 3 or argv[1] not in ('android', 'ios'):
        print(__doc__.strip().split('\n\n')[1], file=sys.stderr)
        sys.exit(2)
    cases = list((android if argv[1] == 'android' else ios)(argv[2]))
    for name, outcome, why in cases:
        print(f'{outcome}: {name}')
        if why:
            print(f'  reason: {why}')
    counts = {}
    for _, outcome, _ in cases:
        counts[outcome] = counts.get(outcome, 0) + 1
    print(f'total {len(cases)}: ' + ', '.join(f'{k} {v}' for k, v in sorted(counts.items())))
    sys.exit(0 if cases else 1)


if __name__ == '__main__':
    main(sys.argv)
