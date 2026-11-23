#!/usr/bin/env python3
"""Print Patrol test names and outcomes from result files, then a count line.

Only known test names and failure categories are printed. Unknown names or failures are withheld,
because arbitrary test output may contain keys or tokens of any length.

Usage:
  python3 patrol_results.py android <snapshot>/example/build/app/outputs/androidTest-results/connected
  python3 patrol_results.py ios <tmp>/ios-tests-<target>-<attempt>.json

The iOS input is the output of `xcrun xcresulttool get test-results tests --path <xcresult>`.
Exits with 1 when no test cases are found or a name or outcome is unrecognized.
"""

import glob
import json
import os
import sys
import urllib.parse
import xml.etree.ElementTree as ET


TEST_NAMES = (
    'loads SmartCaptcha and enables the controls',
    'shows the challenge when the checkbox is tapped',
    'destroys SmartCaptcha and disables the controls',
)


def safe_name(name):
    matches = [known for known in TEST_NAMES if known in (name or '')]
    return matches[0] if len(matches) == 1 else '[unrecognized test name]'


def reason(text):
    text = text or ''
    if 'A SemanticsHandle was active at the end of the test.' in text:
        return 'SemanticsHandle active at end of test'
    if 'AndroidAutomatorClient._sendRequest' in text:
        return 'AndroidAutomatorClient request failed or timed out'
    if 'TimeoutException' in text:
        return 'TimeoutException'
    return 'failure details withheld'


def android(directory):
    for path in sorted(glob.glob(os.path.join(directory, '**', '*.xml'), recursive=True)):
        for case in ET.parse(path).getroot().iter('testcase'):
            failure = case.find('failure')
            if failure is None:
                failure = case.find('error')
            if failure is not None:
                text = '\n'.join(filter(None, (failure.get('message'), failure.text)))
                yield safe_name(case.get('name')), 'Failed', reason(text)
            elif case.find('skipped') is not None:
                yield safe_name(case.get('name')), 'Skipped', None
            else:
                yield safe_name(case.get('name')), 'Passed', None


def ios(path):
    def walk(node):
        if node.get('nodeType') == 'Test Case':
            messages = [c.get('name') for c in node.get('children', []) if c.get('nodeType') == 'Failure Message']
            # Patrol form-encodes iOS test names ("app_test+SmartCaptcha+...").
            name = urllib.parse.unquote_plus(node.get('name') or '')
            outcome = node.get('result')
            yield (
                safe_name(name),
                outcome if outcome in ('Passed', 'Failed', 'Skipped') else 'Unknown',
                reason('\n'.join(filter(None, messages))) if messages else None,
            )
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
    valid = cases and all(
        name != '[unrecognized test name]' and outcome != 'Unknown'
        for name, outcome, _ in cases
    )
    sys.exit(0 if valid else 1)


if __name__ == '__main__':
    main(sys.argv)
