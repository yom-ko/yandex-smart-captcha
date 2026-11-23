import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest
import xml.etree.ElementTree as ET


SKILL = Path(__file__).resolve().parents[1]
SCRIPTS = SKILL / 'scripts'


class HelperTests(unittest.TestCase):
    def test_snapshot_excludes_ignored_env_and_untracked_sensitive_subtree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / 'repo'
            repo.mkdir()
            subprocess.run(['git', 'init', '-q', str(repo)], check=True)
            (repo / 'example').mkdir()
            (repo / 'private').mkdir()
            (repo / 'pubspec.yaml').write_text('name: fixture\n')
            (repo / '.gitignore').write_text('example/.env\n')
            (repo / 'deleted.txt').write_text('tracked\n')
            subprocess.run(
                ['git', '-C', str(repo), 'add', 'pubspec.yaml', '.gitignore', 'deleted.txt'],
                check=True,
            )
            (repo / 'deleted.txt').unlink()
            (repo / 'example' / '.env').write_text('SYNTHETIC=fixture\n')
            (repo / 'private' / 'secret.txt').write_text('untracked synthetic secret\n')
            (repo / 'private-other.txt').write_text('public\n')
            (repo / '[literal]\nname.txt').write_text('untracked\n')
            original_index = (repo / '.git' / 'index').read_bytes()
            run = root / 'run'
            run.mkdir()
            result = subprocess.run(
                ['bash', str(SCRIPTS / 'snapshot.sh'), str(run), './private/'],
                cwd=repo, text=True, capture_output=True, check=True,
            )
            self.assertIn('SNAPSHOT_OK', result.stdout)
            self.assertFalse((run / 'snapshot' / 'example' / '.env').exists())
            self.assertFalse((run / 'snapshot' / 'private').exists())
            self.assertFalse((run / 'snapshot' / 'deleted.txt').exists())
            self.assertEqual((run / 'snapshot' / 'private-other.txt').read_text(), 'public\n')
            self.assertEqual((run / 'snapshot' / '[literal]\nname.txt').read_text(), 'untracked\n')
            for content in ('SYNTHETIC=fixture\n', 'untracked synthetic secret\n'):
                secret_hash = subprocess.check_output(
                    ['git', 'hash-object', '--stdin'], input=content, text=True,
                ).strip()
                self.assertFalse((run / 'objects' / secret_hash[:2] / secret_hash[2:]).exists())
            self.assertEqual((repo / '.git' / 'index').read_bytes(), original_index)

    def test_snapshot_rejects_ambiguous_sensitive_paths_before_staging(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / 'repo'
            repo.mkdir()
            subprocess.run(['git', 'init', '-q', str(repo)], check=True)
            (repo / 'pubspec.yaml').write_text('name: fixture\n')
            subprocess.run(['git', '-C', str(repo), 'add', 'pubspec.yaml'], check=True)
            for index, path in enumerate(('.', './', 'private//nested', 'private/./nested')):
                with self.subTest(path=path):
                    run = root / f'run-{index}'
                    run.mkdir()
                    result = subprocess.run(
                        ['bash', str(SCRIPTS / 'snapshot.sh'), str(run), path],
                        cwd=repo, text=True, capture_output=True,
                    )
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('invalid sensitive path', result.stderr)
                    self.assertFalse((run / 'objects').exists())

    def test_snapshot_excludes_tracked_secrets_and_keeps_ignored_tracked_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / 'repo'
            repo.mkdir()
            subprocess.run(['git', 'init', '-q', str(repo)], check=True)
            (repo / 'example').mkdir()
            (repo / 'private').mkdir()
            (repo / 'pubspec.yaml').write_text('name: fixture\n')
            (repo / '.gitignore').write_text('ignored.txt\n')
            (repo / 'ignored.txt').write_text('tracked\n')
            (repo / 'example' / '.env').write_text('SYNTHETIC=fixture\n')
            (repo / 'private' / 'secret.txt').write_text('synthetic\n')
            subprocess.run(
                ['git', '-C', str(repo), 'add', '-f', 'pubspec.yaml', '.gitignore',
                 'ignored.txt', 'example/.env', 'private/secret.txt'],
                check=True,
            )
            (repo / 'ignored.txt').write_text('working tree\n')
            original_index = (repo / '.git' / 'index').read_bytes()
            run = root / 'run'
            run.mkdir()
            result = subprocess.run(
                ['bash', str(SCRIPTS / 'snapshot.sh'), str(run), 'private'],
                cwd=repo, text=True, capture_output=True, check=True,
            )
            self.assertIn('SNAPSHOT_OK', result.stdout)
            self.assertEqual((run / 'snapshot' / 'ignored.txt').read_text(), 'working tree\n')
            self.assertFalse((run / 'snapshot' / 'example' / '.env').exists())
            self.assertFalse((run / 'snapshot' / 'private' / 'secret.txt').exists())
            secret_hash = subprocess.check_output(
                ['git', 'hash-object', '--stdin'], input='SYNTHETIC=fixture\n', text=True,
            ).strip()
            self.assertFalse((run / 'objects' / secret_hash[:2] / secret_hash[2:]).exists())
            self.assertEqual((repo / '.git' / 'index').read_bytes(), original_index)

    def test_events_rejects_missing_log(self):
        result = subprocess.run(
            ['bash', str(SCRIPTS / 'events.sh'), '/nonexistent/e2e-log', 'count', 'onCaptchaReady'],
            text=True, capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')

    def test_events_count_existing_log(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / 'events.log'
            log.write_text('called: onCaptchaReady\ncalled: onCaptchaReady\n')
            result = subprocess.run(
                ['bash', str(SCRIPTS / 'events.sh'), str(log), 'count', 'onCaptchaReady'],
                text=True, capture_output=True, check=True,
            )
            self.assertEqual(result.stdout.strip(), '2')

    def test_android_record_cleans_run_owned_path_on_pull_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            adb = root / 'adb'
            adb.write_text(
                '#!/bin/sh\n'
                'echo "$*" >> "$MOCK_LOG"\n'
                'case "$*" in\n'
                '  *"shell mktemp"*) echo /data/local/tmp/e2e-rec.TEST123 ;;\n'
                '  *" pull "*) exit 7 ;;\n'
                'esac\n'
            )
            adb.chmod(0o755)
            env = dict(os.environ, E2E_TMP=directory, MOCK_LOG=str(root / 'calls'),
                       PATH=directory + os.pathsep + os.environ['PATH'])
            result = subprocess.run(
                ['bash', str(SCRIPTS / 'android.sh'), 'test-device', 'record', '1', str(root / 'record.mp4')],
                env=env, text=True, capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            calls = (root / 'calls').read_text()
            self.assertIn('shell rm -f /data/local/tmp/e2e-rec.TEST123', calls)
            self.assertNotIn('/sdcard/e2e-rec.mp4', calls)

    def test_patrol_uses_failure_body_without_printing_secrets(self):
        with tempfile.TemporaryDirectory() as directory:
            case = ET.Element('testcase', name='loads SmartCaptcha and enables the controls FAKE_SHORT_VALUE')
            failure = ET.SubElement(case, 'failure', message='java.lang.AssertionError: Dart test failed')
            failure.text = 'A SemanticsHandle was active at the end of the test. token=FAKE_SHORT_VALUE'
            suite = ET.Element('testsuite')
            suite.append(case)
            ET.ElementTree(suite).write(Path(directory) / 'result.xml')
            result = subprocess.run(
                ['python3', str(SCRIPTS / 'patrol_results.py'), 'android', directory],
                text=True, capture_output=True, check=True,
            )
            self.assertIn('SemanticsHandle active at end of test', result.stdout)
            self.assertNotIn('FAKE_SHORT_VALUE', result.stdout)

    def test_patrol_rejects_unknown_test_name_without_printing_it(self):
        with tempfile.TemporaryDirectory() as directory:
            suite = ET.Element('testsuite')
            ET.SubElement(suite, 'testcase', name='FAKE_SHORT_VALUE')
            ET.ElementTree(suite).write(Path(directory) / 'result.xml')
            result = subprocess.run(
                ['python3', str(SCRIPTS / 'patrol_results.py'), 'android', directory],
                text=True, capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('FAKE_SHORT_VALUE', result.stdout)

    def run_fake_chrome(self, response, target='owned', command='nav',
                        ws_url='ws://127.0.0.1:9333/devtools/page/owned'):
        source = """
          class FakeSocket {
            constructor() { queueMicrotask(() => this.onopen()); }
            send(text) {
              const { id } = JSON.parse(text);
              if (process.env.RESPONSE === 'close') queueMicrotask(() => this.onclose());
              else queueMicrotask(() => this.onmessage({ data: JSON.stringify({ id, ...JSON.parse(process.env.RESPONSE) }) }));
            }
            close() {}
          }
          globalThis.WebSocket = FakeSocket;
          globalThis.fetch = async () => ({ ok: true, json: async () => [
            { type: 'page', id: 'owned', webSocketDebuggerUrl: process.env.WS_URL }
          ] });
          process.argv = ['node', 'web.mjs', 'chrome', process.env.COMMAND,
            process.env.COMMAND === 'block' ? '1' : 'http://unused.invalid'];
          await import(process.env.SCRIPT_URL);
        """
        env = dict(os.environ, E2E_CHROME_PORT='9333', E2E_CHROME_TARGET_ID=target, RESPONSE=response,
                   COMMAND=command, WS_URL=ws_url,
                   SCRIPT_URL=(SCRIPTS / 'web.mjs').as_uri())
        return subprocess.run(
            ['node', '--input-type=module', '-e', source], env=env,
            text=True, capture_output=True, timeout=5,
        )

    def test_chrome_protocol_error_is_not_reported_as_navigation(self):
        result = self.run_fake_chrome('{"error":{"code":-32000,"message":"FAKE_SHORT_VALUE"}}')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('navigated', result.stdout)
        self.assertNotIn('FAKE_SHORT_VALUE', result.stderr)

    def test_chrome_navigation_error_is_not_reported_as_success(self):
        result = self.run_fake_chrome('{"result":{"errorText":"failure"}}')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('navigated', result.stdout)

    def test_chrome_refuses_a_different_page(self):
        result = self.run_fake_chrome('{"result":{}}', target='other')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('navigated', result.stdout)

    def test_chrome_refuses_a_nonlocal_debugger(self):
        result = self.run_fake_chrome('{"result":{}}', ws_url='ws://remote.invalid:9333/page')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('navigated', result.stdout)

    def test_chrome_disconnect_fails_without_waiting_for_timeout(self):
        result = self.run_fake_chrome('close')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('navigated', result.stdout)

    def test_chrome_state_rejects_untrusted_event_text(self):
        response = '{"result":{"result":{"value":"{\\"events\\":\\"E2E: token=FAKE_SHORT_VALUE\\",\\"buttons\\":{}}"}}}'
        result = self.run_fake_chrome(response, command='state')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('FAKE_SHORT_VALUE', result.stdout + result.stderr)

    def test_chrome_state_accepts_expected_events(self):
        response = '{"result":{"result":{"value":"{\\"events\\":\\"E2E: Wasm: false | called: onCaptchaReady\\",\\"buttons\\":{\\"Execute\\":\\"enabled\\"}}"}}}'
        result = self.run_fake_chrome(response, command='state')
        self.assertEqual(result.returncode, 0)
        self.assertIn('onCaptchaReady', result.stdout)

    def test_chrome_block_holds_the_connection(self):
        start = time.monotonic()
        result = self.run_fake_chrome('{"result":{}}', command='block')
        self.assertGreaterEqual(time.monotonic() - start, 0.9)
        self.assertEqual(result.returncode, 0)
        self.assertIn('blocking', result.stdout)
        self.assertIn('block ok', result.stdout)


if __name__ == '__main__':
    unittest.main()
